#!/usr/bin/env bash
set -euo pipefail
sudo mv /tmp/lab-nginx.saved /etc/nginx/conf.d/lab.conf
sudo systemctl reload nginx
