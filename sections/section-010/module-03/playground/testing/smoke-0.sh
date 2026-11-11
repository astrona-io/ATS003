#!/usr/bin/env bash
set -euo pipefail
for tool in ip netplan; do command -v "$tool"; done
ip link show private0 >/dev/null
