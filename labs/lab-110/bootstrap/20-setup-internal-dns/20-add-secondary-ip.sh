#!/usr/bin/env bash
# Bootstrap: adds 192.168.10.80 as a secondary address on loopback so
# this single VM can plausibly answer as the internal DNS server at
# that address (`dig @192.168.10.80 ...`), matching the scenario's
# addressing without needing a second host.

set -eu

if ! ip addr show dev lo | grep -q '192\.168\.10\.80/32'; then
  sudo ip addr add 192.168.10.80/32 dev lo
fi
