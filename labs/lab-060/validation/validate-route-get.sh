#!/usr/bin/env bash
# Checks that `ip route get 10.10.30.5` (a table lookup, no packet sent)
# actually resolves via gateway 10.10.20.1 on dev eth1.

set -u

expected_via="10.10.20.1"
expected_dev="eth1"

out="$(ip route get 10.10.30.5 2>/dev/null)"

if [[ -z "$out" ]]; then
  echo "FAIL: route-get - 'ip route get 10.10.30.5' produced no output"
  exit 1
fi

if [[ "$out" == *"via $expected_via"* && "$out" == *"dev $expected_dev"* ]]; then
  echo "PASS: route-get (10.10.30.5 resolves via $expected_via dev $expected_dev)"
  exit 0
else
  echo "FAIL: route-get - got '$out', expected via $expected_via dev $expected_dev"
  exit 1
fi
