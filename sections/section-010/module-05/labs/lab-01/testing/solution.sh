#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/netplan/70-dhcp0.yaml >/dev/null <<'REFERENCE_FILE'
network:
  version: 2
  ethernets:
    dhcp0:
      dhcp4: true
      dhcp4-overrides:
        use-routes: false
        use-dns: false
REFERENCE_FILE
sudo chmod 600 /etc/netplan/70-dhcp0.yaml
sudo netplan apply
for i in $(seq 1 30); do ip -4 addr show dhcp0 | grep -q "10.77.0.1[0-4][0-9]/" && break; sleep 2; done
