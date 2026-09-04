#!/usr/bin/env bash
# Bootstrap: starts a trivial local listener on port 6001 so the
# port 6000 -> 6001 nftables redirect the task asks for is testable
# end-to-end on this single VM (there is no separate downstream host
# to redirect to here). python3 ships in the base LFCS image.

set -eu

sudo tee /etc/systemd/system/lab-port-6001.service > /dev/null <<'EOF'
[Unit]
Description=Lab target listener on port 6001 (nftables redirect destination)
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 6001
Restart=always
User=nobody
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now lab-port-6001.service
