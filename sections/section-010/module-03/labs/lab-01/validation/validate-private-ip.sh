#!/usr/bin/env bash
# Checks /opt/course/private_ip holds an RFC1918 address that is actually
# bound to a real local interface on this host.

set -u

path="/opt/course/private_ip"

if [[ ! -f "$path" ]]; then
  echo "FAIL: private_ip - $path does not exist"
  exit 1
fi

actual="$(tr -d '[:space:]' < "$path")"

rfc1918_regex='^(10\.([0-9]{1,3}\.){2}[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3})$'

if [[ ! "$actual" =~ $rfc1918_regex ]]; then
  echo "FAIL: private_ip - '$actual' is not a private RFC1918 address"
  exit 1
fi

if ! hostname -I | tr ' ' '\n' | grep -qx "$actual"; then
  echo "FAIL: private_ip - '$actual' is not bound to any local interface (hostname -I: $(hostname -I))"
  exit 1
fi

echo "PASS: private_ip ($path = '$actual', bound to a local interface)"
exit 0
