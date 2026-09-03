#!/usr/bin/env bash
# Checks reverse resolution: getent hosts 192.168.10.71 -> app-srv1

set -u

expected="app-srv1"

actual="$(getent hosts 192.168.10.71 | awk '{$1=""; print $0}' | xargs)"

if [[ "$actual" == *"$expected"* ]]; then
  echo "PASS: hosts-reverse (getent hosts 192.168.10.71 includes '$expected')"
  exit 0
else
  echo "FAIL: hosts-reverse - getent hosts 192.168.10.71 = '$actual', expected to include '$expected'"
  exit 1
fi
