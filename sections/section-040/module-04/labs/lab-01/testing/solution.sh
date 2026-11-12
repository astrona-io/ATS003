#!/usr/bin/env bash
set -euo pipefail
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/10-lab.conf >/dev/null <<'REFERENCE_FILE'
[Resolve]
DNS=10.55.0.53
Domains=lab.example
REFERENCE_FILE
sudo systemctl restart systemd-resolved
printf '%s
' '198.51.100.80 www.lab.example' | sudo tee -a /etc/hosts
sudo resolvectl flush-caches
