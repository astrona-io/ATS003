#!/usr/bin/env bash
# Checks that something is actually listening on TCP port 8080, bound to
# an address reachable from outside the host (not loopback-only).

set -u

output="$(sudo ss -tulpn 2>/dev/null | grep -E '(^|[[:space:]])8080([[:space:]]|$)' | grep -i 'LISTEN')"

if [[ -z "$output" ]]; then
  echo "FAIL: listening - nothing is bound to port 8080 (expected a LISTEN entry from 'ss -tulpn')"
  exit 1
fi

if echo "$output" | grep -q '127\.0\.0\.1:8080'; then
  echo "FAIL: listening - port 8080 is bound to 127.0.0.1 only, not reachable remotely: $output"
  exit 1
fi

echo "PASS: listening (ss -tulpn shows: $output)"
exit 0
