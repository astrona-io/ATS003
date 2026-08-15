#!/usr/bin/env bash
# Checks that the live kernel routing table has a route to 10.10.30.0/24
# via gateway 10.10.20.1 on dev eth1 (from `ip route show`).

set -u

expected_via="10.10.20.1"
expected_dev="eth1"

line="$(ip route show 10.10.30.0/24 2>/dev/null)"

if [[ -z "$line" ]]; then
  echo "FAIL: route-live - no route found for 10.10.30.0/24 in 'ip route show'"
  exit 1
fi

if [[ "$line" == *"via $expected_via"* && "$line" == *"dev $expected_dev"* ]]; then
  echo "PASS: route-live (10.10.30.0/24 -> $line)"
  exit 0
else
  echo "FAIL: route-live - got '$line', expected via $expected_via dev $expected_dev"
  exit 1
fi
