#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
set -euo pipefail
iface=$(ip -o -4 addr show | awk '$4 == "172.20.10.10/24" {print $2}')
test -n "$iface"
sudo tee /etc/netplan/90-lfcs-route.yaml >/dev/null <<EOF
network:
  version: 2
  ethernets:
    $iface:
      addresses: [172.20.10.10/24]
      routes:
        - to: 172.20.20.0/24
          via: 172.20.10.1
EOF
sudo chmod 600 /etc/netplan/90-lfcs-route.yaml
sudo netplan apply
ASTRONA_STUDENT_SCRIPT
