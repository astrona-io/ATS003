#!/usr/bin/env bash
# Checks that the live kernel routing table has a route to 10.10.30.0/24
# via the gateway VM's real resolved address (from `ip route show`).

set -u

gw_host="astrona-ats-003-lab-060-gateway"
gw_ip="$(getent hosts "$gw_host" 2>/dev/null | awk '{print $1}' | head -n1)"

if [[ -z "$gw_ip" ]]; then
  echo "FAIL: route-live - could not resolve $gw_host to an address"
  exit 1
fi

line="$(ip route show 10.10.30.0/24 2>/dev/null)"

if [[ -z "$line" ]]; then
  echo "FAIL: route-live - no route found for 10.10.30.0/24 in 'ip route show'"
  exit 1
fi

if [[ "$line" == *"via $gw_ip"* ]]; then
  echo "PASS: route-live (10.10.30.0/24 -> $line)"
  exit 0
else
  echo "FAIL: route-live - got '$line', expected via $gw_ip ($gw_host)"
  exit 1
fi
