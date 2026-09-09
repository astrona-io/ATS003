#!/usr/bin/env bash
# Bootstrap: seeds a stale 127.0.1.1 entry in /etc/hosts matching the
# generic pre-rename hostname, so the static-hostname task also has a
# hosts-file entry that legitimately needs updating.

set -eu

if grep -q '^127\.0\.1\.1' /etc/hosts; then
  sudo sed -i 's/^127\.0\.1\.1.*/127.0.1.1\tubuntu-2404-base/' /etc/hosts
else
  printf '127.0.1.1\tubuntu-2404-base\n' | sudo tee -a /etc/hosts > /dev/null
fi
