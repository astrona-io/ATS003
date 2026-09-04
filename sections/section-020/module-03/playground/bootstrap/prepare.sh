#!/usr/bin/env bash
# OS prep for PLAYGROUND — Multi-Interface Static Routing (playground)
# Runs once when the environment comes up, as a regular user with passwordless
# sudo (the LFCS base image, like the graded labs). Environment preparation
# ONLY: iproute2, iputils-ping, and traceroute all ship in the base image; this
# just gives the two lab NICs their addresses so their connected routes exist.
# It deliberately adds NO static route, NO extra default route, and NO metric
# — building and inspecting the routing table is the whole point of the
# playground.
set -euo pipefail

echo "[playground] static-routing-playground: preparing multi-interface host..."

# Address the two extra NICs if astrona has not already. Their kernel names are
# whatever is not `lo` and not the management interface (the one that already
# carries an IP + the default route). Match by the segment CIDR so this is
# idempotent.
addr_if_missing() {
  local want_cidr="$1" want_addr="$2" dev
  # already configured somewhere? done.
  ip -o -4 addr show | grep -q " ${want_addr}/" && return 0
  for dev in $(ip -o link show up | awk -F': ' '{print $2}' | grep -v '^lo$'); do
    # skip the interface that carries the default route (management)
    ip route show default | grep -q "dev ${dev}\b" && continue
    # skip an interface that already has a global IPv4
    ip -o -4 addr show dev "$dev" scope global | grep -q inet && continue
    sudo ip addr add "${want_addr}/24" dev "$dev"
    sudo ip link set "$dev" up
    echo "[playground] assigned ${want_addr}/24 to ${dev}"
    return 0
  done
  echo "[playground] note: no free interface found for ${want_addr}/24" >&2
}
addr_if_missing 10.0.0.0/24     10.0.0.50
addr_if_missing 192.168.70.0/24 192.168.70.50

echo
echo "[playground] addresses:"
ip -brief -4 addr show || true
echo
echo "[playground] routing table:"
ip route show || true

echo
echo "[playground] ready. Two extra NICs are addressed (10.0.0.50/24 and"
echo "[playground] 192.168.70.50/24); the table holds only connected routes plus"
echo "[playground] the management default. No router answers on either segment —"
echo "[playground] 'ip route get' still resolves through a made-up gateway because"
echo "[playground] it is a lookup, not a send. Do NOT touch the management"
echo "[playground] interface or its default route. See docs/overview.md."
