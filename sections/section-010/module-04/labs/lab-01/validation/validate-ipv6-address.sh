#!/usr/bin/env bash
# Checks that the static IPv6 ULA fd00:10::70/64 is bound to the host's
# primary interface with global scope (not stuck tentative/dadfailed).

set -u

expected="fd00:10::70/64"

iface="$(ip -o -4 route show to default | awk '{print $5}')"
if [[ -z "$iface" ]]; then
  echo "FAIL: ipv6-address - could not detect primary interface (no default route)"
  exit 1
fi

line="$(ip -o -6 addr show dev "$iface" scope global | grep -w "$expected" || true)"

if [[ -z "$line" ]]; then
  echo "FAIL: ipv6-address - $expected not found with scope global on $iface"
  exit 1
fi

if echo "$line" | grep -qw "tentative"; then
  echo "FAIL: ipv6-address - $expected present on $iface but still tentative (DAD not complete)"
  exit 1
fi

if echo "$line" | grep -qw "dadfailed"; then
  echo "FAIL: ipv6-address - $expected present on $iface but dadfailed (duplicate detected)"
  exit 1
fi

echo "PASS: ipv6-address ($expected present on $iface, scope global)"
exit 0
