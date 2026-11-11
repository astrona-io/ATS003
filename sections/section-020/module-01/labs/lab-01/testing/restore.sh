#!/usr/bin/env bash
set -euo pipefail
sudo mv /root/bridge-bond.ci-saved /etc/netplan/99-lab-bridge-bond.yaml
sudo netplan apply
sleep 3
