#!/usr/bin/env bash
set -euo pipefail
sudo sed -i '/app-srv1/d' /etc/hosts
printf '%s\n' '192.168.10.99 app-srv1' | sudo tee -a /etc/hosts >/dev/null
