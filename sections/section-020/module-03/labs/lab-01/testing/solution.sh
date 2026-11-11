#!/usr/bin/env bash
set -euo pipefail
iface=$(ip -o -4 addr show | awk '$4=="10.10.20.5/24"{print $2}')
test -n "$iface"
sudo tee /etc/netplan/99-lab-route.yaml >/dev/null <<REFERENCE_FILE
network:
  version: 2
  ethernets:
    ${iface}:
      addresses: [10.10.20.5/24]
      routes:
        - to: 10.10.30.0/24
          via: 10.10.20.1
REFERENCE_FILE
sudo chmod 600 /etc/netplan/99-lab-route.yaml
sudo netplan apply
