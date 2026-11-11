#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/systemd/network/20-np0.netdev >/dev/null <<'CONFIG'
[NetDev]
Name=np0
Kind=dummy
CONFIG
sudo ip link add np0 type dummy
sudo ip link set np0 up
sudo tee /etc/netplan/90-lab.yaml >/dev/null <<'CONFIG'
network:
  version: 2
  ethernets:
    np0:
      renderer: networkd
      dhcp4: false
      addresses: [192.168.130.50/24]
      optional: true
CONFIG
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
sudo chmod 600 /etc/netplan/90-lab.yaml /etc/netplan/99-lab-extra.yaml
sudo netplan apply
sleep 3
sudo install -d /var/lib/course
ip -4 route show default | awk 'NR==1{print $5}' | sudo tee /var/lib/course/management-interface >/dev/null
