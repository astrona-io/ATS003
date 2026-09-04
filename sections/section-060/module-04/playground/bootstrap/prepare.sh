#!/usr/bin/env bash
# OS prep for PLAYGROUND — Raw Packet Capturing (tcpdump)
# Runs once at startup, as a regular user with passwordless sudo (the LFCS
# base image, like the graded labs). tcpdump, curl, python3, socat, and
# iproute2 all ship in the base image already. This starts a local HTTP
# server and a loop that produces steady loopback traffic, and saves a
# sample capture. Nothing to build — the point is running tcpdump against a
# machine that always has packets moving on `lo`.
set -euo pipefail

echo "[playground] tcpdump-capture-playground: starting traffic + capture tools..."

# --- a local HTTP server to capture conversations with ----------------------
sudo tee /etc/systemd/system/lab-http.service > /dev/null <<'EOF'
[Unit]
Description=tcpdump playground: HTTP server on 127.0.0.1:8080
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 127.0.0.1
Restart=always
DynamicUser=yes
EOF

# --- a loop that keeps loopback traffic flowing ---------------------------
sudo tee /usr/local/bin/lab-traffic.sh > /dev/null <<'EOF'
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
sudo chmod +x /usr/local/bin/lab-traffic.sh

sudo tee /etc/systemd/system/lab-traffic.service > /dev/null <<'EOF'
[Unit]
Description=tcpdump playground: steady loopback traffic generator
After=lab-http.service

[Service]
ExecStart=/usr/local/bin/lab-traffic.sh
Restart=always
DynamicUser=yes
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now lab-http.service lab-traffic.service 2>/dev/null || true

# --- a sample .pcap so `tcpdump -r` works from the first minute ------------
sleep 3
sudo timeout 15 tcpdump -i lo -n -c 40 -w /usr/local/share/lab-sample.pcap 2>/dev/null || true
sudo chmod 644 /usr/local/share/lab-sample.pcap 2>/dev/null || true

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
