#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Checks forward resolution: getent hosts app-srv1 -> 192.168.10.71

set -u

expected="192.168.10.71"

actual="$(getent hosts app-srv1 | awk '{print $1}')"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: hosts-forward (getent hosts app-srv1 = '$actual')"
  exit 0
else
  echo "FAIL: hosts-forward - getent hosts app-srv1 = '$actual', expected '$expected'"
  exit 1
fi
ASTRONA_STUDENT_SCRIPT
