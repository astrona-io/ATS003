#!/usr/bin/env bash
set -euo pipefail
sudo cp /etc/netplan/99-lab-bridge-bond.yaml /root/bridge-bond.ci-saved
sudo sed -i 's/interfaces: \[dummy0\]/interfaces: []/' /etc/netplan/99-lab-bridge-bond.yaml
sudo netplan apply
sudo ip link set dummy0 nomaster
