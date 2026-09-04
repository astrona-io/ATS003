#!/usr/bin/env bash
# OS prep for PLAYGROUND — Nginx Reverse Proxy
# Runs once at startup, as a regular user with passwordless sudo (the LFCS
# base image, like the graded labs). Environment preparation ONLY: nginx,
# curl, and python3 all ship in the base image already. This starts two tiny
# backend apps that echo the request they received, so you can write proxy
# blocks and see exactly what nginx forwards. Nginx is left serving its stock
# default page — the `location` / `proxy_pass` config is yours to write.
set -euo pipefail

echo "[playground] nginx-proxy-playground: preparing backends..."

# --- the request-echo backend -------------------------------------------------
sudo install -d /opt/echo
sudo tee /opt/echo/echo_server.py > /dev/null <<'PY'
#!/usr/bin/env python3
"""Tiny HTTP server that echoes the request line and selected headers as text.
Usage: echo_server.py <port> <label>
"""
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(sys.argv[1])
LABEL = sys.argv[2] if len(sys.argv) > 2 else "backend"
SHOW = ("host", "x-forwarded-for", "x-forwarded-proto", "x-real-ip",
        "x-forwarded-host", "user-agent", "connection")


class Echo(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _reply(self):
        lines = [f"backend   : {LABEL} (127.0.0.1:{PORT})",
                 f"method    : {self.command}",
                 f"path      : {self.path}"]
        for h in SHOW:
            if h in self.headers:
                lines.append(f"{h:<10}: {self.headers[h]}")
        body = ("\n".join(lines) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    do_GET = _reply
    do_POST = _reply
    do_HEAD = _reply

    def log_message(self, *a):
        pass


HTTPServer(("127.0.0.1", PORT), Echo).serve_forever()
PY
sudo chmod +x /opt/echo/echo_server.py

# --- one systemd unit per backend ------------------------------------------
for spec in "a 9001" "b 9002"; do
  set -- $spec
  name="$1"; port="$2"
  sudo tee "/etc/systemd/system/backend-${name}.service" > /dev/null <<EOF
[Unit]
Description=Playground echo backend ${name} (127.0.0.1:${port})
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/echo/echo_server.py ${port} backend-${name}
Restart=always
DynamicUser=yes

[Install]
WantedBy=multi-user.target
EOF
done

sudo systemctl daemon-reload
sudo systemctl enable --now backend-a.service backend-b.service 2>/dev/null || true

# --- nginx: stock default site, just make sure it is up ---------------------
sudo systemctl enable --now nginx 2>/dev/null || true
sudo nginx -t 2>&1 || true
sudo systemctl reload nginx 2>/dev/null || true

echo
echo "[playground] backend check:"
sleep 1
curl -s --max-time 3 http://127.0.0.1:9001/hello || true
curl -s --max-time 3 http://127.0.0.1:9002/hello || true

echo
echo "[playground] ready. nginx serves its default page on :80. Two echo"
echo "[playground] backends run on 127.0.0.1:9001 (backend-a) and :9002"
echo "[playground] (backend-b). Add proxy config under /etc/nginx/ (e.g. edit"
echo "[playground] sites-available/default or drop a file in conf.d/), run"
echo "[playground] 'sudo nginx -t' then 'sudo systemctl reload nginx', and curl"
echo "[playground] localhost to see what each backend received. See docs/overview.md."
