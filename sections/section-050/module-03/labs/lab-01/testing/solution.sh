#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/ssh/sshd-banner >/dev/null <<'REFERENCE_FILE'
Authorized access only. All activity is logged.
REFERENCE_FILE
sudo tee /etc/ssh/sshd_config.d/00-lab-hardening.conf >/dev/null <<'REFERENCE_FILE'
X11Forwarding no
PasswordAuthentication no
Banner /etc/ssh/sshd-banner
Match User elena
    PasswordAuthentication yes
Match all
REFERENCE_FILE
sudo sshd -t
sudo systemctl reload ssh
