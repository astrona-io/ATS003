#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks that something is actually listening on TCP port 8080, bound to
# an address reachable from outside the host (not loopback-only).

set -u

output="$(sudo ss -Hltnp 'sport = :8080' 2>/dev/null)"

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
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
