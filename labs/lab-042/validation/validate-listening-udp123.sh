#!/usr/bin/env bash
# Checks that chronyd is actually listening on UDP/123, the port
# needed to answer NTP queries from other hosts once `allow` is
# configured.

set -u

listening="$(sudo ss -ulnp 2>/dev/null | grep -E ':123[[:space:]]' || true)"

if [[ -n "$listening" ]]; then
  echo "PASS: listening-udp123 - chronyd is listening on UDP/123"
  exit 0
else
  echo "FAIL: listening-udp123 - nothing is listening on UDP/123"
  exit 1
fi
