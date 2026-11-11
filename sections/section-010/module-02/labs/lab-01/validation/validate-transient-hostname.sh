#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks the live/transient hostname reported by `hostname` equals web-srv1,
# proving the rename is live now and not only pending a reboot.

set -u

expected="web-srv1"
actual="$(hostname)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: transient hostname (hostname = '$actual')"
  exit 0
else
  echo "FAIL: transient hostname - hostname = '$actual', expected '$expected'"
  exit 1
fi
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
