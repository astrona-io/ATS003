#!/usr/bin/env bash
set -euo pipefail
sudo ip link set dummy0 master br0
sleep 3
