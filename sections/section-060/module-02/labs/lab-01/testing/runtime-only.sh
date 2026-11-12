#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/netplan/99-lab-extra.yaml >/dev/null <<'CONFIG'
network:
  version: 2
  ethernets:
    np0:
      renderer: networkd
      dhcp4: false
      addresses: [192.168.130.60/24]
      optional: true
CONFIG
sudo chmod 600 /etc/netplan/99-lab-extra.yaml
