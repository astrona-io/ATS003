#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/nginx/conf.d/lab.conf >/dev/null <<'CONFIG'
server {
    listen 8001;
    location / {
        rewrite ^.*$ /special break;
        proxy_pass http://127.0.0.1:2222;
    }
}
CONFIG
sudo nginx -t
sudo systemctl reload nginx
