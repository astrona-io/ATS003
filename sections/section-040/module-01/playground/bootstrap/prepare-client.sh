#!/usr/bin/env bash
# Per-VM OS prep for the ntp-client VM — PLAYGROUND (NTP Client Time Sync)
# Gives you a clean slate: chrony is installed and running, but every default
# source is commented out so `chronyc sources` starts EMPTY. Adding a source
# (pointing at the ntp-server VM) and watching the client lock on is the whole
# point — this script does NOT add it for you.
set -euo pipefail

echo "[playground] ntp-client: clearing default chrony sources..."

CONF=/etc/chrony/chrony.conf
[ -f "$CONF" ] || CONF=/etc/chrony.conf

# Comment out any active `pool` / `server` lines shipped in the default config.
sed -i -E 's/^([[:space:]]*)(pool|server)[[:space:]]/\1#\2 /' "$CONF"

# Ubuntu also pulls sources from drop-in dirs and DHCP. Neutralise those so the
# starting state is genuinely "no sources".
if [ -d /etc/chrony/sources.d ]; then
  find /etc/chrony/sources.d -name '*.sources' -exec sh -c \
    'printf "# cleared for playground\n" > "$1"' _ {} \;
fi
rm -f /run/chrony-dhcp/*.sources 2>/dev/null || true

systemctl restart chrony 2>/dev/null || systemctl restart chronyd 2>/dev/null || true

echo "[playground] ntp-client: chrony restarted with no sources configured."
echo "[playground] Add one with:  sudo chronyc add server 192.168.100.10 iburst"
echo "[playground] or persistently by adding a 'server' line to $CONF."
chronyc sources 2>/dev/null || true
