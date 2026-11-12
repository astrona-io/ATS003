#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' 'pool 0.pool.ntp.org iburst minpoll 4 maxpoll 10' | sudo tee -a /etc/chrony/chrony.conf
sudo systemctl restart chrony
chronyc waitsync 60 0 0 2
