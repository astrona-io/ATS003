#!/usr/bin/env bash
set -euo pipefail
if [ -f /etc/netplan/99-lab-extra.yaml ]; then sudo mv /etc/netplan/99-lab-extra.yaml /etc/netplan/99-lab-extra.yaml.disabled; fi
sudo netplan apply
sleep 3
