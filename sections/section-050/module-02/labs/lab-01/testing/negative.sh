#!/usr/bin/env bash
set -euo pipefail
sudo mv /etc/nginx/conf.d/lab.conf /tmp/lab-nginx.saved
sudo systemctl reload nginx
