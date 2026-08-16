#!/usr/bin/env bash
# Checks that the live kernel routing table has a route to 10.10.30.0/24
# via gateway 10.10.20.1 (the gateway VM's real address on backend-net).

set -u

expected_via="10.10.20.1"

line="$(ip route show 10.10.30.0/24 2>/dev/null)"

if [[ -z "$line" ]]; then
  echo "FAIL: route-live - no route found for 10.10.30.0/24 in 'ip route show'"
  exit 1
fi

if [[ "$line" == *"via $expected_via"* ]]; then
  echo "PASS: route-live (10.10.30.0/24 -> $line)"
  exit 0
else
  echo "FAIL: route-live - got '$line', expected via $expected_via"
  exit 1
fi
