#!/usr/bin/env bash
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
