#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/systemd/network/20-bondport0.netdev >/dev/null <<'NETDEV'
[NetDev]
Name=bondport0
Kind=dummy
NETDEV
sudo ip link add bondport0 type dummy
sudo ip link set bondport0 up
sudo tee /etc/systemd/network/20-bondport1.netdev >/dev/null <<'NETDEV'
[NetDev]
Name=bondport1
Kind=dummy
NETDEV
sudo ip link add bondport1 type dummy
sudo ip link set bondport1 up
echo "Practice interfaces ready; management networking unchanged."
