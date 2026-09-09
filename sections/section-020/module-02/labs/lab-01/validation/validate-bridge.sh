#!/usr/bin/env bash
# Checks br0 exists, is administratively UP, and enslaves dummy0

set -u

if ! ip link show br0 &> /dev/null; then
  echo "FAIL: bridge - br0 does not exist"
  exit 1
fi

flags="$(ip link show br0 | head -n1)"

if ! echo "$flags" | grep -q ',UP'; then
  echo "FAIL: bridge - br0 exists but is not administratively UP ($flags)"
  exit 1
fi

master="$(ip -o link show dummy0 2> /dev/null | grep -o 'master [^ ]*' | awk '{print $2}')"

if [[ "$master" != "br0" ]]; then
  echo "FAIL: bridge - dummy0 master is '${master:-none}', expected 'br0'"
  exit 1
fi

echo "PASS: bridge (br0 is UP, dummy0 master=br0)"
exit 0
