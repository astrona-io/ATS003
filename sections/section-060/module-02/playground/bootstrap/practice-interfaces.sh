#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/systemd/network/20-np0.netdev >/dev/null <<'NETDEV'
[NetDev]
Name=np0
Kind=dummy
NETDEV
sudo ip link add np0 type dummy
sudo ip link set np0 up
echo "Practice interfaces ready; management networking unchanged."
