#!/usr/bin/env bash
# Checks that the short name db resolves through the search domain.
set -u

answer="$(getent hosts db 2>/dev/null | awk '{print $1; exit}')"

if [[ "$answer" == "203.0.113.20" ]]; then
  echo "PASS: short-name (db resolves to 203.0.113.20)"
  exit 0
fi

echo "FAIL: short-name - getent hosts db returned '${answer:-nothing}' instead of 203.0.113.20"
exit 1
