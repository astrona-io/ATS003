#!/usr/bin/env bash
set -euo pipefail
sudo cp /tmp/lab-topology.saved /etc/netplan/99-lab-bridge.yaml
sudo netplan apply
sleep 5
