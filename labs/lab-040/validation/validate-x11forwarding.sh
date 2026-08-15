#!/usr/bin/env bash
# Confirms X11Forwarding is disabled in the effective sshd config (sshd -T),
# the authoritative resolved view, rather than grepping the raw config file.

set -u

actual="$(sudo sshd -T 2>/dev/null | grep -i '^x11forwarding' | awk '{print $2}')"
expected="no"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: x11forwarding (effective value = '$actual')"
  exit 0
else
  echo "FAIL: x11forwarding - effective value = '$actual', expected '$expected'"
  exit 1
fi
