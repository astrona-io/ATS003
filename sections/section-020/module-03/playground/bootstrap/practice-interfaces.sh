#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/systemd/network/20-route0.netdev >/dev/null <<'NETDEV'
[NetDev]
Name=route0
Kind=dummy
NETDEV
sudo ip link add route0 type dummy
sudo ip link set route0 up
sudo tee /etc/systemd/network/20-route1.netdev >/dev/null <<'NETDEV'
[NetDev]
Name=route1
Kind=dummy
NETDEV
sudo ip link add route1 type dummy
sudo ip link set route1 up
echo "Practice interfaces ready; management networking unchanged."
