#!/usr/bin/env bash
# Checks that the public key of cadet is accepted by pilot.
set -u

public_key="$(sudo awk '{print $2}' /home/cadet/.ssh/id_ed25519.pub 2>/dev/null)"
if [[ -z "$public_key" ]]; then
  echo "FAIL: key-installed - cadet has no public key to look for"
  exit 1
fi

if sudo grep -qF "$public_key" /home/pilot/.ssh/authorized_keys 2>/dev/null; then
  echo "PASS: key-installed (the public key of cadet is in /home/pilot/.ssh/authorized_keys)"
  exit 0
fi

echo "FAIL: key-installed - the public key of cadet is not in /home/pilot/.ssh/authorized_keys"
exit 1
