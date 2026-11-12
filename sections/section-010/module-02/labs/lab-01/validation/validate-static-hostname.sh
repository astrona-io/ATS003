#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks the static hostname persisted in /etc/hostname equals web-srv1

set -u

path="/etc/hostname"
expected="web-srv1"

if [[ ! -f "$path" ]]; then
  echo "FAIL: static hostname - $path does not exist"
  exit 1
fi

actual="$(cat "$path")"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: static hostname ($path = '$actual')"
  exit 0
else
  echo "FAIL: static hostname - $path = '$actual', expected '$expected'"
  exit 1
fi
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
