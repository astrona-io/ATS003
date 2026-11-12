#!/usr/bin/env bash
set -eu
printf '\nallow 192.168.10.0/24\n' | sudo tee -a /etc/chrony/chrony.conf >/dev/null
sudo systemctl restart chrony
