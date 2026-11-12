#!/usr/bin/env bash
set -euo pipefail
if ! sudo netplan get bonds.bond0 | grep -q interfaces; then
  echo 'FAIL: persistence - bond0 is not declared in Netplan'; exit 1
fi
echo 'PASS: bond0 persistent declaration'
