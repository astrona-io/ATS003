#!/usr/bin/env bash
# Confirms 8443/tcp is allowed in the public zone's permanent (saved)
# configuration, so it survives a reload/reboot.

set -u

ports="$(sudo firewall-cmd --zone=public --list-ports --permanent 2>/dev/null)"

if grep -qw "8443/tcp" <<< "$ports"; then
  echo "PASS: port-8443-permanent (8443/tcp present in permanent ports: '$ports')"
  exit 0
else
  echo "FAIL: port-8443-permanent - 8443/tcp not in permanent ports: '$ports'"
  exit 1
fi
