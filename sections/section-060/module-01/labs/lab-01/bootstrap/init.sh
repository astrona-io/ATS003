#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/NetworkManager/conf.d/99-lab-managed.conf >/dev/null <<'CONFIG'
[keyfile]
unmanaged-devices=*,except:interface-name:nm0
CONFIG
sudo systemctl enable --now NetworkManager
sudo systemctl restart NetworkManager
sudo nmcli connection add type dummy ifname nm0 con-name lab-static ipv4.method manual ipv4.addresses 192.168.120.99/24 ipv4.never-default yes ipv6.method disabled connection.autoconnect no
sudo nmcli connection up lab-static
sudo install -d /var/lib/course
ip -4 route show default | awk 'NR==1{print $5}' | sudo tee /var/lib/course/management-interface >/dev/null
