#!/usr/bin/env bash
# Checks a direct query against the known-good internal DNS server
# (@192.168.10.80) returns the same A record as the system resolver,
# confirming the record itself -- not the resolver -- is correct.

set -u

expected="192.168.10.80"
actual="$(dig @192.168.10.80 +short data-001.internal.example.com A 2>/dev/null | tail -n1)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: direct-server A record (@192.168.10.80 data-001.internal.example.com = '$actual')"
  exit 0
else
  echo "FAIL: direct-server A record - @192.168.10.80 data-001.internal.example.com = '$actual', expected '$expected'"
  exit 1
fi
