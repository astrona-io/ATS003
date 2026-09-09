#!/usr/bin/env bash
# Checks `bridge link show` reports dummy0 as a forwarding member of br0

set -u

line="$(bridge link show 2> /dev/null | grep 'dummy0')"

if [[ -z "$line" ]]; then
  echo "FAIL: bridge-forwarding - dummy0 not found in 'bridge link show' output"
  exit 1
fi

if ! echo "$line" | grep -q 'master br0'; then
  echo "FAIL: bridge-forwarding - dummy0 is not shown with 'master br0' ($line)"
  exit 1
fi

if ! echo "$line" | grep -q 'state forwarding'; then
  echo "FAIL: bridge-forwarding - dummy0 has not reached 'state forwarding' yet ($line)"
  exit 1
fi

echo "PASS: bridge-forwarding (dummy0 master br0, state forwarding)"
exit 0
