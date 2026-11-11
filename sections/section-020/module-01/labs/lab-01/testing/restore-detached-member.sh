#!/usr/bin/env bash
set -euo pipefail
sudo ip link set dummy1 down
sudo ip link set dummy1 master bond0
sudo ip link set dummy1 up
sleep 5
