#!/usr/bin/env bash
# Bootstrap: deploys the two pre-existing, off-limits apps that the lab's
# scenario refers to as running on web-srv1 (192.168.10.60) ports 1111 and
# 2222. These represent another team's already-live services — the lab
# task is to route around them from a brand-new config file, never to edit
# these two files.
#
# Each app is a minimal Nginx server{} block returning distinct,
# identifiable plaintext so the reverse proxy/load balancer behavior can
# be verified by content, not just HTTP status code.

set -eu

sudo tee /etc/nginx/conf.d/app-1111.conf > /dev/null <<'EOF'
# Pre-existing production app on port 1111.
# Owned by another team - do not edit as part of this lab.
server {
    listen 1111;
    server_name _;

    location / {
        default_type text/plain;
        return 200 "app-1111-root\n";
    }
}
EOF

sudo tee /etc/nginx/conf.d/app-2222.conf > /dev/null <<'EOF'
# Pre-existing production app on port 2222.
# Owned by another team - do not edit as part of this lab.
server {
    listen 2222;
    server_name _;

    location /special {
        default_type text/plain;
        return 200 "app-2222-special\n";
    }

    location / {
        default_type text/plain;
        return 200 "app-2222-root\n";
    }
}
EOF

sudo nginx -t
sudo systemctl reload nginx
