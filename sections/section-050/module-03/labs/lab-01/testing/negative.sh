#!/usr/bin/env bash
set -euo pipefail
sudo sed -i 's/X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config.d/00-lab-hardening.conf
sudo systemctl reload ssh
