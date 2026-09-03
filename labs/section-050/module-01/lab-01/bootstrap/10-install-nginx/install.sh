#!/usr/bin/env bash
# Bootstrap init: installs nginx and makes sure the service is enabled/running.

set -eu

export DEBIAN_FRONTEND=noninteractive

if ! command -v nginx >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y nginx
fi

sudo systemctl enable nginx
sudo systemctl start nginx
