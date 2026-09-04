#!/usr/bin/env bash
# OS prep for PLAYGROUND — Netplan YAML Configurations
# Runs once at startup, as a regular user with passwordless sudo (the LFCS
# base image, like the graded labs). netplan.io and iproute2 both ship in the
# base image already. No netplan file is written for the spare NIC — writing
# it is the point. This script just works out which interface is the spare
# (so the docs can name it) and tightens permissions on the existing netplan
# files so their "world-readable" warning does not clutter every command.
set -euo pipefail

echo "[playground] netplan-yaml-playground: preparing..."

# --- identify the spare NIC: not loopback, not the default-route interface ---
MGMT_DEV="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')"
SPARE_DEV=""
for dev in $(ip -o link show | awk -F': ' '{print $2}' | cut -d@ -f1 | grep -v '^lo$'); do
  [ "$dev" = "$MGMT_DEV" ] && continue
  ip -o -4 addr show dev "$dev" scope global | grep -q inet && continue
  SPARE_DEV="$dev"
  break
done
printf '%s\n' "${SPARE_DEV:-unknown}" | sudo tee /root/lab-spare-iface > /dev/null

echo "[playground] management interface : ${MGMT_DEV:-unknown}  (its /etc/netplan file is off-limits)"
echo "[playground] spare interface       : ${SPARE_DEV:-NOT FOUND}  (write a netplan file for this one)"

# --- tidy up permissions on any existing netplan files ---------------------
if compgen -G "/etc/netplan/*.yaml" >/dev/null; then
  sudo chmod 600 /etc/netplan/*.yaml || true
fi

echo
echo "[playground] existing netplan files:"
ls -l /etc/netplan/ 2>/dev/null || true
echo
echo "[playground] netplan status:"
sudo netplan status 2>/dev/null || sudo netplan get 2>/dev/null || true

echo
echo "[playground] ready. Netplan is native here (renderer: systemd-networkd)."
echo "[playground] The spare NIC '${SPARE_DEV:-<see /root/lab-spare-iface>}' on"
echo "[playground] 192.168.130.0/24 (no DHCP, no router) has NO netplan file."
echo "[playground] Create /etc/netplan/90-lab.yaml (chmod 600), for example:"
echo "[playground]"
echo "[playground]   network:"
echo "[playground]     version: 2"
echo "[playground]     ethernets:"
echo "[playground]       ${SPARE_DEV:-<dev>}:"
echo "[playground]         dhcp4: false"
echo "[playground]         addresses: [192.168.130.50/24]"
echo "[playground]"
echo "[playground] then: sudo netplan generate | netplan try | netplan apply."
echo "[playground] Do NOT edit the management interface's netplan file. See docs/overview.md."
