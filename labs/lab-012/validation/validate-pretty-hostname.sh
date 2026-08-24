#!/usr/bin/env bash
# Checks the pretty hostname reported by hostnamectl matches the
# scenario's cosmetic display name.

set -u

expected="Web Server 1 (Frankfurt)"
actual="$(hostnamectl status --pretty 2>/dev/null)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: pretty hostname (hostnamectl status --pretty = '$actual')"
  exit 0
else
  echo "FAIL: pretty hostname - hostnamectl status --pretty = '$actual', expected '$expected'"
  exit 1
fi
