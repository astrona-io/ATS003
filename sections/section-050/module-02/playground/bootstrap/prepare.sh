#!/usr/bin/env bash
# OS prep for PLAYGROUND — Nginx Load Balancers
# Runs once at startup, as a regular user with passwordless sudo (the LFCS
# base image, like the graded labs). Environment preparation ONLY: nginx,
# curl, and python3 all ship in the base image already. This starts three
# labelled echo backends and a plain round-robin load balancer on :8080. The
# base config balances evenly across all three — changing the balancing method
# and the health-check settings in /etc/nginx/conf.d/lb.conf is the point.
set -euo pipefail

echo "[playground] nginx-lb-playground: preparing backends..."

# --- the request-echo backend (prints which backend answered) ----------------
sudo install -d /opt/echo
sudo tee /opt/echo/echo_server.py > /dev/null <<'PY'
#!/usr/bin/env python3
"""Tiny HTTP server that names itself and echoes the request. Slow mode with ?ms=."""
import sys, time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

PORT = int(sys.argv[1])
LABEL = sys.argv[2] if len(sys.argv) > 2 else "backend"


class Echo(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _reply(self):
        q = parse_qs(urlparse(self.path).query)
        if "ms" in q:
            try:
                time.sleep(min(int(q["ms"][0]), 30000) / 1000.0)
            except ValueError:
                pass
        body = (f"backend : {LABEL} (127.0.0.1:{PORT})\n"
                f"method  : {self.command}\n"
                f"path    : {self.path}\n").encode()
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

for spec in "1 9001" "2 9002" "3 9003"; do
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
sudo systemctl enable --now backend-1.service backend-2.service backend-3.service 2>/dev/null || true

# --- a plain round-robin load balancer on :8080 -----------------------------
sudo tee /etc/nginx/conf.d/lb.conf > /dev/null <<'EOF'
# Load balancer for the playground. Edit the `upstream` block to change the
# balancing method (add `least_conn;`, `ip_hash;`, `hash $request_uri;`) or the
# per-server options (`weight=`, `max_fails=`, `fail_timeout=`, `backup`, `down`),
# then:  sudo nginx -t && sudo systemctl reload nginx
upstream app_pool {
    server 127.0.0.1:9001;
    server 127.0.0.1:9002;
    server 127.0.0.1:9003;
}

server {
    listen 8080;
    server_name _;

    location / {
        proxy_pass http://app_pool;
        proxy_set_header Host $host;
        # proxy_next_upstream error timeout http_502;
    }
}
EOF

sudo systemctl enable --now nginx 2>/dev/null || true
sudo nginx -t 2>&1 || true
sudo systemctl reload nginx 2>/dev/null || true

echo
echo "[playground] round-robin check (:8080):"
sleep 1
for _ in 1 2 3 4; do curl -s --max-time 3 http://127.0.0.1:8080/ | grep '^backend' || true; done

echo
echo "[playground] ready. nginx default page on :80. Load balancer on :8080"
echo "[playground] over app_pool = backend-1/2/3 (127.0.0.1:9001-9003), plain"
echo "[playground] round-robin. Edit /etc/nginx/conf.d/lb.conf, 'sudo nginx -t',"
echo "[playground] 'sudo systemctl reload nginx'. Backends accept ?ms=N to"
echo "[playground] respond slowly. See docs/overview.md."
