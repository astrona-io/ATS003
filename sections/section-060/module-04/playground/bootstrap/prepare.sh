#!/usr/bin/env bash
# OS prep for PLAYGROUND — Raw Packet Capturing (tcpdump)
# Runs once at startup. Environment preparation ONLY: install tcpdump, start a
# local HTTP server and a loop that produces steady loopback traffic, and save a
# sample capture. Nothing to build — the point is running tcpdump against a
# machine that always has packets moving on `lo`.
set -euo pipefail

echo "[playground] tcpdump-capture-playground: starting traffic + capture tools..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y --no-install-recommends tcpdump curl python3 socat iproute2 iputils-ping || true
fi

# --- a local HTTP server to capture conversations with ----------------------
cat > /etc/systemd/system/lab-http.service <<'EOF'
[Unit]
Description=tcpdump playground: HTTP server on 127.0.0.1:8080
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 127.0.0.1
Restart=always
DynamicUser=yes
EOF

# --- a loop that keeps loopback traffic flowing ---------------------------
cat > /usr/local/bin/lab-traffic.sh <<'EOF'
#!/bin/sh
# Every ~2s: one HTTP GET, one ICMP echo, one UDP datagram to a closed port
# (which draws an ICMP port-unreachable back). All on 127.0.0.1.
while :; do
  curl -s -o /dev/null --max-time 2 "http://127.0.0.1:8080/?t=$(date +%s)" || true
  ping -c 1 -W 1 127.0.0.1 >/dev/null 2>&1 || true
  echo "hello-udp" | socat -t1 - UDP:127.0.0.1:9999 >/dev/null 2>&1 || true
  sleep 2
done
EOF
chmod +x /usr/local/bin/lab-traffic.sh

cat > /etc/systemd/system/lab-traffic.service <<'EOF'
[Unit]
Description=tcpdump playground: steady loopback traffic generator
After=lab-http.service

[Service]
ExecStart=/usr/local/bin/lab-traffic.sh
Restart=always
DynamicUser=yes
EOF

systemctl daemon-reload
systemctl enable --now lab-http.service lab-traffic.service 2>/dev/null || true

# --- a sample .pcap so `tcpdump -r` works from the first minute ------------
sleep 3
timeout 15 tcpdump -i lo -n -c 40 -w /usr/local/share/lab-sample.pcap 2>/dev/null || true
chmod 644 /usr/local/share/lab-sample.pcap 2>/dev/null || true

echo
echo "[playground] tcpdump version:"
tcpdump --version 2>&1 | head -n 1 || true
echo
echo "[playground] ready. Loopback (lo) has steady traffic:"
echo "[playground]   HTTP  GET http://127.0.0.1:8080/   (every ~2s)"
echo "[playground]   ICMP  echo to 127.0.0.1            (every ~2s)"
echo "[playground]   UDP   datagram to 127.0.0.1:9999   -> ICMP port-unreachable"
echo "[playground] Sample capture: /usr/local/share/lab-sample.pcap  (tcpdump -r it)"
echo "[playground] Start here:  sudo tcpdump -i lo -n -c 10"
echo "[playground] See docs/overview.md."
