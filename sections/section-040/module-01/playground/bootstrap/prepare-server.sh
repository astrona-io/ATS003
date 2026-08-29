#!/usr/bin/env bash
# Per-VM OS prep for the ntp-server VM — PLAYGROUND (NTP Client Time Sync)
# Turns this VM into a self-contained NTP server for the 192.168.100.0/24
# segment: it serves its own clock at stratum 8 (no upstream needed) and allows
# the client to query it. This is environment setup, not a graded outcome — the
# learning happens on the CLIENT VM.
set -euo pipefail

echo "[playground] ntp-server: writing local-stratum chrony server config..."

CONF=/etc/chrony/chrony.conf
[ -f "$CONF" ] || CONF=/etc/chrony.conf

cat > "$CONF" <<'EOF'
# Playground NTP server — serves local time to the isolated lab segment.
# No upstream source is reachable here, so `local stratum 8` lets this host
# act as a source anyway. Do not copy `local stratum` onto a real server that
# has genuine upstream time.
driftfile /var/lib/chrony/chrony.drift
makestep 1.0 3
rtcsync
local stratum 8
allow 192.168.100.0/24
EOF

systemctl restart chrony 2>/dev/null || systemctl restart chronyd 2>/dev/null || true

echo "[playground] ntp-server: chrony restarted. Serving on 192.168.100.10:123."
chronyc tracking 2>/dev/null || true
