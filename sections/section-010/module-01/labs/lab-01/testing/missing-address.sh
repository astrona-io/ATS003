#!/usr/bin/env bash
set -euo pipefail
iface=$(ip -4 route show default | awk 'NR==1{print $5}')
sudo ip addr del 192.168.10.71/24 dev "$iface"
