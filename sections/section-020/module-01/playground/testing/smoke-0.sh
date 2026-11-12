#!/usr/bin/env bash
set -euo pipefail
for tool in ip bridge; do command -v "$tool"; done
ip link show bondport0 >/dev/null
ip link show bondport1 >/dev/null
