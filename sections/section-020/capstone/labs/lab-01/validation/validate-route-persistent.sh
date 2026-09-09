#!/usr/bin/env bash
# Checks that the route to 10.10.30.0/24 via 10.10.20.1 is declared in a
# persistent network config -- Netplan, systemd-networkd, NetworkManager,
# or a legacy route-* script -- not just added live with `ip route add`.
# Any one of these mechanisms re-applying the route at boot is sufficient.

set -u

dest="10.10.30.0/24"
dest_bare="10.10.30.0"
gw="10.10.20.1"

found=""

# Netplan
for f in /etc/netplan/*.yaml /etc/netplan/*.yml; do
  [[ -f "$f" ]] || continue
  if sudo grep -q "$dest_bare" "$f" 2>/dev/null && sudo grep -q "$gw" "$f" 2>/dev/null; then
    found="netplan:$f"
    break
  fi
done

# systemd-networkd
if [[ -z "$found" ]]; then
  for f in /etc/systemd/network/*.network; do
    [[ -f "$f" ]] || continue
    if sudo grep -q "$dest" "$f" 2>/dev/null && sudo grep -q "$gw" "$f" 2>/dev/null; then
      found="systemd-networkd:$f"
      break
    fi
  done
fi

# NetworkManager
if [[ -z "$found" ]]; then
  if sudo grep -rq "$dest_bare" /etc/NetworkManager/system-connections/ 2>/dev/null \
     && sudo grep -rq "$gw" /etc/NetworkManager/system-connections/ 2>/dev/null; then
    found="NetworkManager:/etc/NetworkManager/system-connections/"
  fi
fi

# Legacy RHEL-family route-* file
if [[ -z "$found" ]]; then
  for f in /etc/sysconfig/network-scripts/route-*; do
    [[ -f "$f" ]] || continue
    if sudo grep -q "$dest" "$f" 2>/dev/null && sudo grep -q "$gw" "$f" 2>/dev/null; then
      found="legacy:$f"
      break
    fi
  done
fi

if [[ -n "$found" ]]; then
  echo "PASS: persistent route to $dest via $gw found ($found)"
  exit 0
else
  echo "FAIL: persistent-route - no Netplan/systemd-networkd/NetworkManager/legacy config declares a route to $dest via $gw"
  exit 1
fi
