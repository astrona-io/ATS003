#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks /etc/hosts's 127.0.1.1 local-resolution line was updated to the
# new hostname, not left stale after the rename.

set -u

expected="web-srv1"
line="$(grep '127\.0\.1\.1' /etc/hosts || true)"

if [[ -z "$line" ]]; then
  echo "FAIL: /etc/hosts 127.0.1.1 entry - no 127.0.1.1 line found"
  exit 1
fi

if echo "$line" | grep -qw "$expected"; then
  echo "PASS: /etc/hosts 127.0.1.1 entry ('$line')"
  exit 0
else
  echo "FAIL: /etc/hosts 127.0.1.1 entry - '$line', expected to contain '$expected'"
  exit 1
fi
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
