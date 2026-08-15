#!/usr/bin/env bash
# Confirms https is allowed in the public zone's permanent (saved)
# configuration, so it survives a reload/reboot.

set -u

services="$(firewall-cmd --zone=public --list-services --permanent 2>/dev/null)"

if grep -qw "https" <<< "$services"; then
  echo "PASS: https-permanent (https present in permanent services: '$services')"
  exit 0
else
  echo "FAIL: https-permanent - https not in permanent services: '$services'"
  exit 1
fi
