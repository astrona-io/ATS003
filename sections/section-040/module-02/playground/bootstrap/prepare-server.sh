#!/usr/bin/env bash
# Per-VM OS prep for the ntp-server VM — PLAYGROUND (NTP Server Mode)
# Gives chrony a clock to serve (`local stratum 10`) but deliberately leaves out
# the `allow` directive, so the daemon refuses every client query. Opening it up
# with `allow` is the whole point — this script does NOT do it for you.
set -euo pipefail

echo "[playground] ntp-server: writing chrony.conf WITHOUT an allow line..."

CONF=/etc/chrony/chrony.conf
[ -f "$CONF" ] || CONF=/etc/chrony.conf

sudo tee "$CONF" > /dev/null <<'EOF'
# Playground NTP server — has a servable clock but serves NOBODY yet.
# There is no reachable upstream here, so `local stratum 10` lets this host be
# a source on its own. Add an `allow <cidr>` line (and restart) to let clients
# on the lab segment query it.
driftfile /var/lib/chrony/chrony.drift
makestep 1.0 3
rtcsync
local stratum 10
# allow 192.168.101.0/24     <-- you add this
EOF

sudo systemctl restart chrony 2>/dev/null || sudo systemctl restart chronyd 2>/dev/null || true

echo "[playground] ntp-server: chrony restarted. local stratum 10, no allow."
sudo chronyc tracking 2>/dev/null || true
