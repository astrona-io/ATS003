#!/usr/bin/env bash
set -euo pipefail
if ! sudo netplan get bridges.br0 | grep -q interfaces; then
  echo 'FAIL: persistence - br0 is not declared in Netplan'; exit 1
fi
echo 'PASS: br0 persistent declaration'
