#!/usr/bin/env bash
# Checks that the IPv6 ULA fd00:10::70 actually answers a ping, proving
# it is bound and not just listed in `ip addr`.

set -u

target="fd00:10::70"

if ping -c1 -W2 "$target" >/dev/null 2>&1; then
  echo "PASS: ipv6-reachable ($target responded to ping)"
  exit 0
else
  echo "FAIL: ipv6-reachable - $target did not respond to ping -c1"
  exit 1
fi
