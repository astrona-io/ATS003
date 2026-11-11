#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
set -euo pipefail
sudo systemctl disable --now firewalld || true
sudo sysctl -w net.ipv4.ip_forward=0
sudo nft flush ruleset
ASTRONA_STUDENT_SCRIPT
