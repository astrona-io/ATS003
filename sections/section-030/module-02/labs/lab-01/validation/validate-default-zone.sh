#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Confirms firewall-cmd --get-default-zone reports public.

set -u

expected="public"
actual="$(sudo firewall-cmd --get-default-zone 2>/dev/null)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: default-zone (default zone = '$actual')"
  exit 0
else
  echo "FAIL: default-zone - default zone = '$actual', expected '$expected'"
  exit 1
fi
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
