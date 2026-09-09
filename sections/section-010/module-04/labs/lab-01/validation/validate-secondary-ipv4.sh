#!/usr/bin/env bash
# Checks that the secondary IPv4 address 192.168.10.71/24 is live on the
# host's primary interface, in addition to (not instead of) its original
# address.

set -u

expected="192.168.10.71/24"

iface="$(ip -o -4 route show to default | awk '{print $5}')"
if [[ -z "$iface" ]]; then
  echo "FAIL: secondary-ipv4 - could not detect primary interface (no default route)"
  exit 1
fi

addr_count="$(ip -o -4 addr show dev "$iface" | wc -l)"

if [[ "$addr_count" -lt 2 ]]; then
  echo "FAIL: secondary-ipv4 - only $addr_count IPv4 address(es) on $iface, expected the original plus $expected"
  exit 1
fi

if ip -o -4 addr show dev "$iface" | grep -qw "$expected"; then
  echo "PASS: secondary-ipv4 ($expected present on $iface alongside the original address)"
  exit 0
else
  echo "FAIL: secondary-ipv4 - $expected not found on $iface"
  exit 1
fi
