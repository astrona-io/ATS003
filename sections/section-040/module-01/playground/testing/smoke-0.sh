#!/usr/bin/env bash
set -euo pipefail
for tool in chronyc; do command -v "$tool"; done
ip -o -4 addr show | grep -F " 192.168.100.10/" >/dev/null
