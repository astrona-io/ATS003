#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks the pretty hostname reported by hostnamectl matches the
# scenario's cosmetic display name.

set -u

expected="Web Server 1 (Frankfurt)"
actual="$(hostnamectl --pretty 2>/dev/null)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: pretty hostname (hostnamectl --pretty = '$actual')"
  exit 0
else
  echo "FAIL: pretty hostname - hostnamectl --pretty = '$actual', expected '$expected'"
  exit 1
fi
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
