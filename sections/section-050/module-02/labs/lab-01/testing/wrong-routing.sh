#!/usr/bin/env bash
set -euo pipefail
sudo sed -i '/server 127.0.0.1:2222;/d' /etc/nginx/conf.d/lab.conf
sudo systemctl reload nginx
