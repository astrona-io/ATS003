#!/usr/bin/env bash
# Checks bond0 exists in active-backup mode with dummy1 and dummy2 enslaved

set -u

path="/proc/net/bonding/bond0"

if [[ ! -f "$path" ]]; then
  echo "FAIL: bond-mode - $path does not exist (bond0 not created)"
  exit 1
fi

info="$(cat "$path")"

if ! echo "$info" | grep -q 'Bonding Mode: fault-tolerance (active-backup)'; then
  echo "FAIL: bond-mode - bond0 is not in active-backup mode"
  exit 1
fi

if ! echo "$info" | grep -q 'Slave Interface: dummy1'; then
  echo "FAIL: bond-mode - dummy1 is not a slave of bond0"
  exit 1
fi

if ! echo "$info" | grep -q 'Slave Interface: dummy2'; then
  echo "FAIL: bond-mode - dummy2 is not a slave of bond0"
  exit 1
fi

echo "PASS: bond-mode (bond0 active-backup, dummy1+dummy2 enslaved)"
exit 0
