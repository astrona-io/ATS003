#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/systemd/network/20-bridgeport0.netdev >/dev/null <<'NETDEV'
[NetDev]
Name=bridgeport0
Kind=veth

[Peer]
Name=bridgeport1
NETDEV
sudo ip link add bridgeport0 type veth peer name bridgeport1
echo "Practice interfaces ready; management networking unchanged."
