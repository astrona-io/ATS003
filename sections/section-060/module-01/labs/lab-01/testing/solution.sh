#!/usr/bin/env bash
set -euo pipefail
nmcli -f connection,ipv4 connection show lab-static
sudo nmcli connection modify lab-static ipv4.addresses 192.168.120.50/24 connection.autoconnect yes ipv4.never-default yes
sudo nmcli connection up lab-static
ip -br address show nm0
