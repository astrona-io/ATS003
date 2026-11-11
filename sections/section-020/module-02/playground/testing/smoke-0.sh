#!/usr/bin/env bash
set -euo pipefail
for tool in ip bridge; do command -v "$tool"; done
ip link show bridgeport0 >/dev/null
ip link show bridgeport1 >/dev/null
