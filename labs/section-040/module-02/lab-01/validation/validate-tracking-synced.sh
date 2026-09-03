#!/usr/bin/env bash
# Checks that this host is itself synced (chronyd active, Leap status
# Normal, Stratum 1-15) before it can usefully serve time to anything
# downstream - a stratum-16 / not-synchronized server has nothing
# valid to hand out to clients.

set -u

if ! systemctl is-active --quiet chrony 2>/dev/null && ! systemctl is-active --quiet chronyd 2>/dev/null; then
  echo "FAIL: tracking-synced - chronyd service is not active"
  exit 1
fi

tracking="$(chronyc tracking 2>/dev/null)"

if [[ -z "$tracking" ]]; then
  echo "FAIL: tracking-synced - chronyc tracking returned no output"
  exit 1
fi

leap="$(echo "$tracking" | awk -F: '/Leap status/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
stratum="$(echo "$tracking" | awk -F: '/^Stratum/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"

if [[ "$leap" == "Normal" ]] && [[ "$stratum" =~ ^[0-9]+$ ]] && (( stratum >= 1 && stratum <= 15 )); then
  echo "PASS: tracking-synced - Leap status Normal, Stratum $stratum"
  exit 0
else
  echo "FAIL: tracking-synced - Leap status '$leap', Stratum '$stratum' (expected Normal / 1-15)"
  exit 1
fi
