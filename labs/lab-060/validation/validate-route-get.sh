#!/usr/bin/env bash
# Checks that `ip route get 10.10.30.1` (a table lookup, no packet sent)
# actually resolves via the gateway VM's real resolved address.

set -u

gw_host="astrona-ats-003-lab-060-gateway"
gw_ip="$(getent hosts "$gw_host" 2>/dev/null | awk '{print $1}' | head -n1)"

if [[ -z "$gw_ip" ]]; then
  echo "FAIL: route-get - could not resolve $gw_host to an address"
  exit 1
fi

out="$(ip route get 10.10.30.1 2>/dev/null)"

if [[ -z "$out" ]]; then
  echo "FAIL: route-get - 'ip route get 10.10.30.1' produced no output"
  exit 1
fi

if [[ "$out" == *"via $gw_ip"* ]]; then
  echo "PASS: route-get (10.10.30.1 resolves via $gw_ip / $gw_host)"
  exit 0
else
  echo "FAIL: route-get - got '$out', expected via $gw_ip ($gw_host)"
  exit 1
fi
