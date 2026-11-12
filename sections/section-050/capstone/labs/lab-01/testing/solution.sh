#!/usr/bin/env bash
set -euo pipefail
sudo tee /etc/nginx/conf.d/lab.conf >/dev/null <<'REFERENCE_FILE'
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

server {
    listen 8001;
    location / {
        rewrite ^.*$ /special break;
        proxy_pass http://127.0.0.1:2222;
    }
}
REFERENCE_FILE
sudo nginx -t
sudo systemctl reload nginx
