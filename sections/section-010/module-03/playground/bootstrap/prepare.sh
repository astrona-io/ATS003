#!/usr/bin/env bash
# OS prep for PLAYGROUND — Discovering Your Public IP Address
# Runs once when the environment comes up. Environment preparation ONLY: install
# the discovery tools the module uses and put a second private address on the
# host so `ip addr` shows more than one RFC 1918 range. There is no task and no
# grading.
set -euo pipefail

echo "[playground] public-ip-playground: preparing clean host..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  # curl for the HTTP discovery services, dnsutils for `dig` (the DNS method),
  # ca-certificates so HTTPS validates. Non-fatal if a package is missing.
  apt-get install -y --no-install-recommends curl dnsutils ca-certificates || true
fi

# Address the spare NIC from RFC 1918's 172.16.0.0/12 block. The management
# interface already sits in 10.0.0.0/8, so the host then shows two different
# private ranges at once. The spare NIC is the one with no IPv4 address at boot.
LAB_NIC=""
for dev in $(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$'); do
  if ip -o -4 addr show dev "$dev" 2>/dev/null | grep -q 'inet '; then
    continue
  fi
  LAB_NIC="$dev"
  break
done
if [ -n "$LAB_NIC" ]; then
  ip addr add 172.16.20.50/24 dev "$LAB_NIC" 2>/dev/null || true
  ip link set "$LAB_NIC" up || true
fi

echo
echo "[playground] addresses:"
ip -brief addr show || true
echo
echo "[playground] routes:"
ip route show || true

echo
echo "[playground] ready."
echo "[playground]   management NIC       : private address in 10.0.0.0/8, carries the default route"
echo "[playground]   ${LAB_NIC:-<spare-nic>} : 172.16.20.50/24  (private, RFC 1918 172.16.0.0/12)"
echo "[playground]"
echo "[playground] Local view always works:  ip addr show   and   ip route show"
echo "[playground] Internet discovery (curl https://ifconfig.me, the dig myaddr query)"
echo "[playground] only works if this environment has outbound egress. If it does not,"
echo "[playground] those commands time out — the module shows what they return when connected."
echo "[playground] See docs/overview.md."
