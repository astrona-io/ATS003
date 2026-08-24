#!/usr/bin/env bash
# Bootstrap: installs chrony so the base Ubuntu 24.04 image has NTP
# tooling and a default /etc/chrony/chrony.conf for the task to edit.

set -eu

if ! command -v chronyd >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y chrony
fi

sudo systemctl enable chrony
sudo systemctl restart chrony
