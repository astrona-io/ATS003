#!/usr/bin/env bash
# Per-VM OS prep for the ntp-client VM — PLAYGROUND (NTP Server Mode)
# Points chrony straight at the ntp-server VM and starts it. Because the server
# has no `allow` line yet, this client's source will sit in the `?` state —
# reachable on the network, but refused by chrony. That is the "before"
# picture; it flips to `*` once the server is opened up.
set -euo pipefail

echo "[playground] ntp-client: writing chrony.conf pointed at 192.168.101.10..."

CONF=/etc/chrony/chrony.conf
[ -f "$CONF" ] || CONF=/etc/chrony.conf

# Clear any packaged drop-in / DHCP sources so the only source is ours.
if [ -d /etc/chrony/sources.d ]; then
  sudo find /etc/chrony/sources.d -name '*.sources' -exec sh -c \
    'printf "# cleared for playground\n" > "$1"' _ {} \;
fi
sudo rm -f /run/chrony-dhcp/*.sources 2>/dev/null || true

sudo tee "$CONF" > /dev/null <<'EOF'
# Playground NTP client — one source, the lab's ntp-server VM.
driftfile /var/lib/chrony/chrony.drift
makestep 1.0 3
rtcsync
server 192.168.101.10 iburst
EOF

sudo systemctl restart chrony 2>/dev/null || sudo systemctl restart chronyd 2>/dev/null || true

echo "[playground] ntp-client: chrony restarted. Source 192.168.101.10 will be"
echo "[playground] refused until the server gets an 'allow' line."
sudo chronyc sources 2>/dev/null || true
