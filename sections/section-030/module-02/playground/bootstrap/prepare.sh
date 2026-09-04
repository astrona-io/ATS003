#!/usr/bin/env bash
# OS prep for PLAYGROUND — firewalld Zones and Services (playground)
# Runs once when the environment comes up. Environment preparation ONLY:
# install firewalld, start it at its STOCK defaults, address the extra NIC, and
# install a couple of tools for probing ports. It deliberately adds NO custom
# service, opens NO extra port, and moves NO interface between zones — doing
# that with `firewall-cmd` is the whole point of the playground.
set -euo pipefail

echo "[playground] firewalld-zones-playground: preparing host..."

# Runs as a regular user with passwordless sudo (the LFCS base image, like the
# graded labs) — every command that touches packages, the daemon, or links
# needs an explicit `sudo`.
export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  # firewalld     = `firewall-cmd` and the daemon.
  # iproute2      = `ip` (addr / link), used to find and address NICs.
  # curl, python3 = generate and serve test traffic against your own rules.
  # Missing packages are non-fatal for a sandbox.
  sudo apt-get install -y --no-install-recommends \
    firewalld iproute2 curl python3 || true
fi

# Start firewalld at its defaults. On Ubuntu the `public` zone is the default
# and already permits the `ssh` service, so enabling the daemon does not cut the
# SSH session. Nothing custom is configured here.
if command -v firewall-cmd >/dev/null 2>&1; then
  sudo systemctl enable --now firewalld.service || true
  # A brief settle so `firewall-cmd --state` answers cleanly on first login.
  for _ in 1 2 3 4 5; do sudo firewall-cmd --state >/dev/null 2>&1 && break; sleep 1; done
fi

# Give the VM a second local interface to assign between zones. astrona's qemu
# networking backend only supports a runtime.networks segment joined by exactly
# 2 VMs (point-to-point) — a solo playground VM cannot get a second NIC that
# way. A dummy interface is a real kernel netdev with its own name and address
# and needs no peer; firewalld's --change-interface does not care whether the
# device is a physical NIC or a dummy one. Idempotent: safe to re-run.
ensure_dummy_addr() {
  local dev="$1" addr="$2"
  sudo modprobe dummy 2>/dev/null || true
  ip link show "$dev" >/dev/null 2>&1 || sudo ip link add "$dev" type dummy
  ip -o -4 addr show dev "$dev" | grep -q " ${addr}/" || sudo ip addr add "${addr}/24" dev "$dev"
  sudo ip link set "$dev" up
  echo "[playground] assigned ${addr}/24 to ${dev}"
}
ensure_dummy_addr dummy0 192.168.90.10

echo
echo "[playground] addresses:"
ip -brief -4 addr show || true
echo
echo "[playground] firewalld:"
sudo firewall-cmd --state 2>/dev/null || true
sudo firewall-cmd --get-default-zone 2>/dev/null || true
sudo firewall-cmd --get-active-zones 2>/dev/null || true

echo
echo "[playground] ready. firewalld is running at its defaults (default zone"
echo "[playground] 'public', ssh allowed). The VM has its management address"
echo "[playground] plus 192.168.90.10/24 on a local dummy interface for zone/"
echo "[playground] interface experiments. Do NOT remove the ssh service from the"
echo "[playground] zone that holds your SSH interface, set the default zone to"
echo "[playground] 'drop', or enable panic mode — any of those cuts your"
echo "[playground] session. See docs/overview.md."
