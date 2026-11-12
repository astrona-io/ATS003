#!/usr/bin/env bash
set -euo pipefail
for tool in ip ss tcpdump; do command -v "$tool"; done
ip link show np0 >/dev/null
