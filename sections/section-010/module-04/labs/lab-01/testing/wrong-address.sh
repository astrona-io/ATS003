#!/usr/bin/env bash
set -euo pipefail
sudo sed -i 's/192.168.10.71 app-srv1/192.168.10.99 app-srv1/' /etc/hosts
