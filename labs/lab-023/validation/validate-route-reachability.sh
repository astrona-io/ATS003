#!/usr/bin/env bash
# Real end-to-end proof the route works: ping the gateway's own dummy0
# address (10.10.30.1) inside the partner subnet. This only succeeds
# if the route is correct AND the gateway VM is actually forwarding --
# not just present in this host's routing table.

set -u

if ping -c 2 -W 3 10.10.30.1 >/tmp/validate-route-reachability.log 2>&1; then
  echo "PASS: route-reachability (10.10.30.1 replied through the gateway)"
  exit 0
else
  echo "FAIL: route-reachability - 10.10.30.1 did not reply: $(tail -3 /tmp/validate-route-reachability.log)"
  exit 1
fi
