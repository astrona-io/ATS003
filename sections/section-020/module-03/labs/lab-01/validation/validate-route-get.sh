#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks that `ip route get 10.10.30.1` (a table lookup, no packet sent)
# actually resolves via gateway 10.10.20.1.

set -u

expected_via="10.10.20.1"

out="$(ip route get 10.10.30.1 2>/dev/null)"

if [[ -z "$out" ]]; then
  echo "FAIL: route-get - 'ip route get 10.10.30.1' produced no output"
  exit 1
fi

if [[ "$out" == *"via $expected_via"* ]]; then
  echo "PASS: route-get (10.10.30.1 resolves via $expected_via)"
  exit 0
else
  echo "FAIL: route-get - got '$out', expected via $expected_via"
  exit 1
fi
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
