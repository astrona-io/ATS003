#!/usr/bin/env bash
# OS prep for PLAYGROUND — firewalld Zones and Services (playground)
# Runs once when the environment comes up. Environment preparation ONLY:
# install firewalld, start it at its STOCK defaults, address the extra NIC, and
# install a couple of tools for probing ports. It deliberately adds NO custom
# service, opens NO extra port, and moves NO interface between zones — doing
# that with `firewall-cmd` is the whole point of the playground.
set -euo pipefail

echo "[playground] firewalld-zones-playground: preparing host..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  # firewalld     = `firewall-cmd` and the daemon.
  # iproute2      = `ip` (addr / link), used to find and address NICs.
  # curl, python3 = generate and serve test traffic against your own rules.
  # Missing packages are non-fatal for a sandbox.
  apt-get install -y --no-install-recommends \
    firewalld iproute2 curl python3 || true
fi

# Start firewalld at its defaults. On Ubuntu the `public` zone is the default
# and already permits the `ssh` service, so enabling the daemon does not cut the
# SSH session. Nothing custom is configured here.
if command -v firewall-cmd >/dev/null 2>&1; then
  systemctl enable --now firewalld.service || true
  # A brief settle so `firewall-cmd --state` answers cleanly on first login.
  for _ in 1 2 3 4 5; do firewall-cmd --state >/dev/null 2>&1 && break; sleep 1; done
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
addr_if_missing 192.168.90.10

echo
echo "[playground] addresses:"
ip -brief -4 addr show || true
echo
echo "[playground] firewalld:"
firewall-cmd --state 2>/dev/null || true
firewall-cmd --get-default-zone 2>/dev/null || true
firewall-cmd --get-active-zones 2>/dev/null || true

echo
echo "[playground] ready. firewalld is running at its defaults (default zone"
echo "[playground] 'public', ssh allowed). The VM has its management address"
echo "[playground] plus 192.168.90.10/24 on an isolated segment for zone/"
echo "[playground] interface experiments. Do NOT remove the ssh service from the"
echo "[playground] zone that holds your SSH interface, set the default zone to"
echo "[playground] 'drop', or enable panic mode — any of those cuts your"
echo "[playground] session. See docs/overview.md."
