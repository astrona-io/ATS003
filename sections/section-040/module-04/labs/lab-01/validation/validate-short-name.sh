#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks that the short name db resolves through the search domain.
set -u

answer="$(getent hosts db 2>/dev/null | awk '{print $1; exit}')"

if [[ "$answer" == "203.0.113.20" ]]; then
  echo "PASS: short-name (db resolves to 203.0.113.20)"
  exit 0
fi

echo "FAIL: short-name - getent hosts db returned '${answer:-nothing}' instead of 203.0.113.20"
exit 1
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
