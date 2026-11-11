#!/usr/bin/env bash
set -euo pipefail
for tool in ip netplan; do command -v "$tool"; done
