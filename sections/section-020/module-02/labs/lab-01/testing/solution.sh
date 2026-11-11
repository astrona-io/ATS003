#!/usr/bin/env bash
set -euo pipefail
sudo ip link add br0 type bridge
sudo ip link set dummy0 master br0
sudo ip link set br0 type bridge stp_state 0
sudo ip link set br0 up
sudo tee /etc/netplan/99-lab-bridge.yaml >/dev/null <<'CONFIG'
network:
  version: 2
  renderer: networkd
  ethernets:
    dummy0: {}
  bridges:
    br0:
      interfaces:
      - dummy0
      parameters:
        stp: false
CONFIG
sudo chmod 600 /etc/netplan/99-lab-bridge.yaml
sudo netplan generate
sudo netplan apply
sleep 5
