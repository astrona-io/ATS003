#!/usr/bin/env bash
set -euo pipefail
sudo ip link set lab0 up
sudo sed -i 's/10.66.0.20 portal.lab/10.66.0.10 portal.lab/' /etc/hosts
sudo nft delete table inet lab_shield
