#!/usr/bin/env bash
# Confirms https is allowed in the public zone's runtime (live) configuration.

set -u

services="$(firewall-cmd --zone=public --list-services 2>/dev/null)"

if grep -qw "https" <<< "$services"; then
  echo "PASS: https-runtime (https present in runtime services: '$services')"
  exit 0
else
  echo "FAIL: https-runtime - https not in runtime services: '$services'"
  exit 1
fi
