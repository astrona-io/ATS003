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

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  # nftables      = the `nft` command.
  # iproute2      = `ip` (addr / link / route), used to find and address NICs.
  # iputils-ping  = quick reachability checks.
  # ncat, curl    = generate test traffic against your own rules.
  # python3       = `python3 -m http.server <port>` as a throwaway listener.
  # Missing packages are non-fatal for a sandbox.
  apt-get install -y --no-install-recommends \
    nftables iproute2 iputils-ping ncat curl python3 || true
fi

# Start from a blank ruleset. On some images nftables.service loads a stock
# file; flushing here means `nft list ruleset` shows nothing until you add
# something yourself.
if command -v nft >/dev/null 2>&1; then
  nft flush ruleset || true
  systemctl disable --now nftables.service 2>/dev/null || true
fi

# Address the extra NIC if astrona has not already. Its kernel name is whatever
# is up, not `lo`, and not the interface that carries the default route
# (management). Match by the segment address so this is idempotent.
addr_if_missing() {
  local want_addr="$1" dev
  ip -o -4 addr show | grep -q " ${want_addr}/" && return 0
  for dev in $(ip -o link show up | awk -F': ' '{print $2}' | grep -v '^lo$'); do
    ip route show default | grep -q "dev ${dev}\b" && continue
    ip -o -4 addr show dev "$dev" scope global | grep -q inet && continue
    ip addr add "${want_addr}/24" dev "$dev"
    ip link set "$dev" up
    echo "[playground] assigned ${want_addr}/24 to ${dev}"
    return 0
  done
  echo "[playground] note: no free interface found for ${want_addr}/24" >&2
}
addr_if_missing 192.168.80.10

echo
echo "[playground] addresses:"
ip -brief -4 addr show || true
echo
echo "[playground] nftables ruleset:"
nft list ruleset 2>/dev/null || true

echo
echo "[playground] ready. 'nft' is installed and the ruleset is empty. The VM"
echo "[playground] has its management address plus 192.168.80.10/24 on an"
echo "[playground] isolated segment for 'ip saddr' experiments. Start a throwaway"
echo "[playground] listener with 'python3 -m http.server 5000' and probe it with"
echo "[playground] 'curl'. Do NOT add a rule that drops your SSH session on the"
echo "[playground] management interface. See docs/overview.md."
