#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
set -euo pipefail
sudo install -d /opt/lfcs-nat
sudo tee /opt/lfcs-nat/server.py >/dev/null <<'APP'
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write((self.client_address[0] + "\n").encode())
HTTPServer(("172.20.20.20", int(sys.argv[1])), Handler).serve_forever()
APP
sudo tee /etc/systemd/system/lfcs-nat@.service >/dev/null <<'UNIT'
[Unit]
Description=LFCS request source reporter
After=network-online.target
Wants=network-online.target
[Service]
ExecStart=/usr/bin/python3 /opt/lfcs-nat/server.py %i
Restart=on-failure
[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload
sudo systemctl enable --now lfcs-nat@8080 lfcs-nat@8081
if sudo systemctl is-active --quiet firewalld; then
  sudo firewall-cmd --permanent --add-port=8080-8081/tcp
  sudo firewall-cmd --add-port=8080-8081/tcp
fi
ASTRONA_STUDENT_SCRIPT
