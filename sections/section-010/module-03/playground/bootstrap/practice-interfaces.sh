#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/systemd/network/20-private0.netdev >/dev/null <<'NETDEV'
[NetDev]
Name=private0
Kind=dummy
NETDEV
sudo ip link add private0 type dummy
sudo ip link set private0 up
echo "Practice interfaces ready; management networking unchanged."
