#!/usr/bin/env bash
# Checks internal.example.com's MX record resolves to priority 10,
# mail.internal.example.com.

set -u

expected="10 mail.internal.example.com."
actual="$(dig internal.example.com MX +short 2>/dev/null | tail -n1)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: MX record (internal.example.com = '$actual')"
  exit 0
else
  echo "FAIL: MX record - internal.example.com = '$actual', expected '$expected'"
  exit 1
fi
