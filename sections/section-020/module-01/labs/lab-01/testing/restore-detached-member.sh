#!/usr/bin/env bash
set -euo pipefail
sudo cp /tmp/lab-topology.saved /etc/netplan/99-lab-bond.yaml
sudo ip link set dummy1 down
sudo ip link set dummy1 master bond0
sudo ip link set dummy1 up
sudo netplan apply
sleep 5
