#!/usr/bin/env bash
set -euo pipefail
for tool in ip bridge; do command -v "$tool"; done
ip -o -4 addr show | grep -F " 10.0.0.50/" >/dev/null
ip -o -4 addr show | grep -F " 192.168.70.50/" >/dev/null
