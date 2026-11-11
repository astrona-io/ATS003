#!/usr/bin/env bash
set -euo pipefail
sudo ip link set dummy0 down
sudo ip link set dummy0 master br0
sudo ip link set dummy0 up
sleep 5
