#!/usr/bin/env bash
set -euo pipefail
sudo sed -i 's/rewrite \^\.\*\$ \/special break;/# rewrite removed;/' /etc/nginx/conf.d/lab.conf
sudo systemctl reload nginx
