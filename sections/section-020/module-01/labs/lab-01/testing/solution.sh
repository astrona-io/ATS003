#!/usr/bin/env bash
set -euo pipefail
sudo ip link add name br0 type bridge
sudo ip link set br0 up
sudo ip link set dummy0 master br0
sudo ip link set br0 type bridge stp_state 0
sudo ip link add bond0 type bond mode active-backup
for iface in dummy1 dummy2; do
 sudo ip link set "$iface" down
 sudo ip link set "$iface" master bond0
 sudo ip link set "$iface" up
done
sudo ip link set bond0 up
sudo tee /etc/netplan/99-lab-bridge-bond.yaml >/dev/null <<'REFERENCE_FILE'
network:
  version: 2
  renderer: networkd
  ethernets:
    dummy0: {}
    dummy1: {}
    dummy2: {}
  bridges:
    br0:
      interfaces: [dummy0]
  bonds:
    bond0:
      interfaces: [dummy1, dummy2]
      parameters:
        mode: active-backup
REFERENCE_FILE
sudo chmod 600 /etc/netplan/99-lab-bridge-bond.yaml
sudo netplan generate
sudo netplan apply
sleep 3
