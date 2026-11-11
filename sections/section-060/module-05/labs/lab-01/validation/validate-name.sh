#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Checks that the name portal.lab resolves to 10.66.0.10 the way applications ask.
set -u

answer="$(getent hosts portal.lab 2>/dev/null | awk '{print $1; exit}')"

if [[ "$answer" == "10.66.0.10" ]]; then
  echo "PASS: name (portal.lab resolves to 10.66.0.10)"
  exit 0
fi

echo "FAIL: name - portal.lab resolves to '${answer:-nothing}' instead of 10.66.0.10"
exit 1
ASTRONA_STUDENT_SCRIPT
