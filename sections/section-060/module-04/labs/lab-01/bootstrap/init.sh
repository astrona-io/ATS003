#!/usr/bin/env bash
set -euo pipefail
sudo install -d -m 755 /opt/course /srv/lab-capture
sudo chown student:student /opt/course
cat /proc/sys/kernel/random/uuid | sudo tee /srv/lab-capture/token >/dev/null
sudo tee /etc/systemd/system/lab-capture-http.service >/dev/null <<'CONFIG'
[Unit]
Description=HTTP fixture for packet capture
After=network.target
[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 127.0.0.1 --directory /srv/lab-capture
Restart=on-failure
User=nobody
[Install]
WantedBy=multi-user.target
CONFIG
sudo tee /usr/local/bin/lab-capture-traffic >/dev/null <<'CONFIG'
#!/usr/bin/env bash
while :; do
  curl --noproxy '*' -fsS --max-time 2 http://127.0.0.1:8080/token >/dev/null || true
  ping -c 1 -W 1 127.0.0.1 >/dev/null 2>&1 || true
  sleep 1
done
CONFIG
sudo chmod 755 /usr/local/bin/lab-capture-traffic
sudo tee /etc/systemd/system/lab-capture-traffic.service >/dev/null <<'CONFIG'
[Unit]
Description=HTTP and ICMP capture traffic
After=lab-capture-http.service
[Service]
ExecStart=/usr/local/bin/lab-capture-traffic
Restart=on-failure
User=nobody
[Install]
WantedBy=multi-user.target
CONFIG
sudo systemctl daemon-reload
sudo systemctl enable --now lab-capture-http lab-capture-traffic
for i in $(seq 1 20); do
  if curl --noproxy '*' -fsS http://127.0.0.1:8080/token >/dev/null; then exit 0; fi
  sleep 1
done
echo 'HTTP capture fixture did not start' >&2
exit 2
