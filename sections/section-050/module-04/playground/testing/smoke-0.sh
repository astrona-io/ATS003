#!/usr/bin/env bash
set -euo pipefail
for tool in ssh ssh-keygen; do command -v "$tool"; done
sudo /usr/sbin/sshd -t
systemctl is-active --quiet ssh
