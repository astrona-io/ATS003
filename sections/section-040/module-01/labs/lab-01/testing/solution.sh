#!/usr/bin/env bash
set -euo pipefail
sudo sed -i -E '/^(pool|server)[[:space:]]/d' /etc/chrony/chrony.conf
for host in 0.pool.ntp.org 1.pool.ntp.org ntp.ubuntu.com 0.debian.pool.ntp.org; do
 printf 'pool %s iburst minpoll 4 maxpoll 10
' "$host" | sudo tee -a /etc/chrony/chrony.conf
done
sudo systemctl restart chrony
chronyc waitsync 60 0 0 2
