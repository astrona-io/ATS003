#!/usr/bin/env bash
# Confirms this VM is actually acting as the partner-subnet gateway:
# IP forwarding is on, and dummy0 is up with 10.10.30.1/24 -- the
# address the target VM's route ultimately reaches.

set -u

fwd="$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo 0)"

if [[ "$fwd" != "1" ]]; then
  echo "FAIL: gateway-ready - net.ipv4.ip_forward is '$fwd', expected 1"
  exit 1
fi

if ! ip -4 addr show dummy0 2>/dev/null | grep -q '10\.10\.30\.1/24'; then
  echo "FAIL: gateway-ready - dummy0 does not have 10.10.30.1/24"
  exit 1
fi

if ! ip link show dummy0 2>/dev/null | grep -qE 'state UP|UP,LOWER_UP'; then
  echo "FAIL: gateway-ready - dummy0 is not up"
  exit 1
fi

echo "PASS: gateway-ready (ip_forward=1, dummy0 10.10.30.1/24 up)"
exit 0
