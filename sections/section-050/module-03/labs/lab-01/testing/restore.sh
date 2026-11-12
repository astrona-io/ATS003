#!/usr/bin/env bash
set -euo pipefail
sudo sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config.d/00-lab-hardening.conf
sudo systemctl reload ssh
