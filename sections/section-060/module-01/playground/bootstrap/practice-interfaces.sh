#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/systemd/network/20-nm0.netdev >/dev/null <<'NETDEV'
[NetDev]
Name=nm0
Kind=dummy
NETDEV
sudo ip link add nm0 type dummy
sudo ip link set nm0 up
echo "Practice interfaces ready; management networking unchanged."
