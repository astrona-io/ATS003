#!/usr/bin/env bash
# Checks internal.example.com's NS record resolves to ns1.internal.example.com.

set -u

expected="ns1.internal.example.com."
actual="$(dig internal.example.com NS +short 2>/dev/null | tail -n1)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: NS record (internal.example.com = '$actual')"
  exit 0
else
  echo "FAIL: NS record - internal.example.com = '$actual', expected '$expected'"
  exit 1
fi
