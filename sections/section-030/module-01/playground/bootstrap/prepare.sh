#!/usr/bin/env bash
# OS prep for PLAYGROUND — Packet Filtering with nftables (playground)
# Runs once when the environment comes up. Environment preparation ONLY:
# install `nft` and a handful of tools for generating and observing traffic,
# bring up the extra NIC so a second local source address exists, and flush the
# nftables ruleset so it starts empty. It deliberately creates NO table, NO
# chain, and NO rule — building that structure is the whole point of the
# playground.
set -euo pipefail

echo "[playground] nftables-filtering-playground: preparing host..."

# Runs as a regular user with passwordless sudo (the LFCS base image, like the
# graded labs) — every command that touches packages, the ruleset, services, or
# links needs an explicit `sudo`.
export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  # nftables      = the `nft` command.
  # iproute2      = `ip` (addr / link / route), used to find and address NICs.
  # iputils-ping  = quick reachability checks.
  # ncat, curl    = generate test traffic against your own rules.
  # python3       = `python3 -m http.server <port>` as a throwaway listener.
  # Missing packages are non-fatal for a sandbox.
  sudo apt-get install -y --no-install-recommends \
    nftables iproute2 iputils-ping ncat curl python3 || true
fi

# Start from a blank ruleset. On some images nftables.service loads a stock
# file; flushing here means `nft list ruleset` shows nothing until you add
# something yourself.
if command -v nft >/dev/null 2>&1; then
  sudo nft flush ruleset || true
  sudo systemctl disable --now nftables.service 2>/dev/null || true
fi

# Give the VM a second local IPv4 address to aim `ip saddr` rules at. astrona's
# qemu networking backend only supports a runtime.networks segment joined by
# exactly 2 VMs (point-to-point) — a solo playground VM cannot get a second NIC
# that way. A dummy interface is a real kernel netdev with its own address and
# needs no peer, so it stands in for "a second local source address" here.
# Idempotent: safe to re-run.
ensure_dummy_addr() {
  local dev="$1" addr="$2"
  sudo modprobe dummy 2>/dev/null || true
  ip link show "$dev" >/dev/null 2>&1 || sudo ip link add "$dev" type dummy
  ip -o -4 addr show dev "$dev" | grep -q " ${addr}/" || sudo ip addr add "${addr}/24" dev "$dev"
  sudo ip link set "$dev" up
  echo "[playground] assigned ${addr}/24 to ${dev}"
}
ensure_dummy_addr dummy0 192.168.80.10

echo
echo "[playground] addresses:"
ip -brief -4 addr show || true
echo
echo "[playground] nftables ruleset:"
sudo nft list ruleset 2>/dev/null || true

echo
echo "[playground] ready. 'nft' is installed and the ruleset is empty. The VM"
echo "[playground] has its management address plus 192.168.80.10/24 on a local"
echo "[playground] dummy interface for 'ip saddr' experiments. Start a throwaway"
echo "[playground] listener with 'python3 -m http.server 5000' and probe it with"
echo "[playground] 'curl'. Do NOT add a rule that drops your SSH session on the"
echo "[playground] management interface. See docs/overview.md."
