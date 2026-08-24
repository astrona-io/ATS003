#!/usr/bin/env bash
# Confirms firewall-cmd --get-default-zone reports public.

set -u

expected="public"
actual="$(sudo firewall-cmd --get-default-zone 2>/dev/null)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: default-zone (default zone = '$actual')"
  exit 0
else
  echo "FAIL: default-zone - default zone = '$actual', expected '$expected'"
  exit 1
fi
