#!/usr/bin/env bash
set -euo pipefail
sudo netplan get ethernets.np0
sudo cat /etc/netplan/90-lab.yaml /etc/netplan/99-lab-extra.yaml
sudo mv /etc/netplan/99-lab-extra.yaml /etc/netplan/99-lab-extra.yaml.disabled
sudo netplan generate
sudo netplan apply
sleep 3
ip -br address show np0
