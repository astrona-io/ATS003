#!/usr/bin/env bash
# Confirms 8443/tcp is allowed in the public zone's runtime (live)
# configuration.

set -u

ports="$(sudo firewall-cmd --zone=public --list-ports 2>/dev/null)"

if grep -qw "8443/tcp" <<< "$ports"; then
  echo "PASS: port-8443-runtime (8443/tcp present in runtime ports: '$ports')"
  exit 0
else
  echo "FAIL: port-8443-runtime - 8443/tcp not in runtime ports: '$ports'"
  exit 1
fi
