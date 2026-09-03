#!/usr/bin/env bash
# Bootstrap: deploys a real, minimal web application listening on
# 0.0.0.0:8080 as a systemd service, so ss/tcpdump have a genuine listener
# to find (matching the "myapp" process in the lab's scenario/solution).

set -eu

sudo mkdir -p /opt/webapp
if [[ ! -f /opt/webapp/index.html ]]; then
  echo "<html><body>web-srv1 app OK</body></html>" | sudo tee /opt/webapp/index.html > /dev/null
fi

sudo tee /etc/systemd/system/myapp.service > /dev/null <<'EOF'
[Unit]
Description=Lab web application (port 8080)
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/webapp
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 0.0.0.0
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now myapp.service
