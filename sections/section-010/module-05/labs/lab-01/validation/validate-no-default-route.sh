#!/usr/bin/env bash
# Checks that dhcp0 carries no default route and some other default route remains.
set -u

if ip -4 route show default | grep -q 'dev dhcp0'; then
  echo "FAIL: routes - a default route uses dhcp0"
  exit 1
fi
if ! ip -4 route show default | grep -q '^default'; then
  echo "FAIL: routes - the management default route is gone"
  exit 1
fi
echo "PASS: routes (no default route on dhcp0, management route intact)"
exit 0
