#!/usr/bin/env bash
# Checks the system's default resolver (dig with no @server) returns
# the expected A record for data-001.internal.example.com.

set -u

expected="192.168.10.80"
actual="$(dig +short data-001.internal.example.com A 2>/dev/null | tail -n1)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: system-resolver A record (data-001.internal.example.com = '$actual')"
  exit 0
else
  echo "FAIL: system-resolver A record - data-001.internal.example.com = '$actual', expected '$expected'"
  exit 1
fi
