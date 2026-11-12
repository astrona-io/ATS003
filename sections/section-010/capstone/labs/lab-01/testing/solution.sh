#!/usr/bin/env bash
set -euo pipefail
iface=$(ip -4 route show default | awk 'NR==1{print $5}')
sudo tee /etc/netplan/99-lab-secondary.yaml >/dev/null <<REFERENCE_FILE
network:
  version: 2
  ethernets:
    ${iface}:
      dhcp4: true
      addresses: [192.168.10.71/24, 'fd00:10::70/64']
REFERENCE_FILE
sudo chmod 600 /etc/netplan/99-lab-secondary.yaml
sudo netplan apply
printf '%s
' '192.168.10.71 app-srv1' | sudo tee -a /etc/hosts
sleep 3
