#!/usr/bin/env bash
set -euo pipefail
sudo ip link add bond0 type bond mode active-backup
for iface in dummy1 dummy2; do
  sudo ip link set "$iface" down
  sudo ip link set "$iface" master bond0
  sudo ip link set "$iface" up
done
sudo ip link set bond0 up
sudo tee /etc/netplan/99-lab-bond.yaml >/dev/null <<'CONFIG'
network:
  version: 2
  renderer: networkd
  ethernets:
    dummy1: {}
    dummy2: {}
  bonds:
    bond0:
      interfaces:
      - dummy1
      - dummy2
      parameters:
        mode: active-backup
CONFIG
sudo chmod 600 /etc/netplan/99-lab-bond.yaml
sudo netplan generate
sudo netplan apply
sleep 5
