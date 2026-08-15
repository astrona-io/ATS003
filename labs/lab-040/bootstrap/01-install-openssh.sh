#!/usr/bin/env bash
# Bootstrap: ensures openssh-server is installed and enabled, and installs
# sshpass so validation can perform real password-based SSH login checks.

set -eu

if ! dpkg -s openssh-server >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
fi

if ! command -v sshpass >/dev/null 2>&1; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y sshpass
fi

sudo systemctl enable --now sshd 2>/dev/null || sudo systemctl enable --now ssh
