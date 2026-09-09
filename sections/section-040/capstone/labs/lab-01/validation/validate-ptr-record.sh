#!/usr/bin/env bash
# Checks the reverse (PTR) lookup for 192.168.10.80 resolves back to
# data-001.internal.example.com.

set -u

expected="data-001.internal.example.com."
actual="$(dig -x 192.168.10.80 +short 2>/dev/null | tail -n1)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: PTR record (192.168.10.80 = '$actual')"
  exit 0
else
  echo "FAIL: PTR record - 192.168.10.80 = '$actual', expected '$expected'"
  exit 1
fi
