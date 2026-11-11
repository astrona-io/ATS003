#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/nginx/conf.d/lab.conf >/dev/null <<'CONFIG'
upstream lab_backends {
    server 127.0.0.1:1111;
    server 127.0.0.1:2222;
}
server {
    listen 8000;
    location / {
        proxy_pass http://lab_backends;
    }
}
CONFIG
sudo nginx -t
sudo systemctl reload nginx
