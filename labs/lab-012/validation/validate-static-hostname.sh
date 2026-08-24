#!/usr/bin/env bash
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
