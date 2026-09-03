#!/usr/bin/env bash
# Checks the client is actually synced through the internal server:
# chronyd active, the server is the currently selected (^*) source,
# Leap status Normal, and stratum one hop above the server (2-15).

set -u

if ! systemctl is-active --quiet chrony 2>/dev/null && ! systemctl is-active --quiet chronyd 2>/dev/null; then
  echo "FAIL: client-synced - chronyd service is not active"
  exit 1
fi

sources="$(chronyc sources 2>/dev/null)"
selected="$(echo "$sources" | grep -E '^\^\*.*astrona-ats-003-lab-042-server' || true)"

if [[ -z "$selected" ]]; then
  echo "FAIL: client-synced - astrona-ats-003-lab-042-server is not the currently selected (^*) source; got: $sources"
  exit 1
fi

tracking="$(chronyc tracking 2>/dev/null)"
leap="$(echo "$tracking" | awk -F: '/Leap status/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
stratum="$(echo "$tracking" | awk -F: '/^Stratum/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"

if [[ "$leap" == "Normal" ]] && [[ "$stratum" =~ ^[0-9]+$ ]] && (( stratum >= 2 && stratum <= 15 )); then
  echo "PASS: client-synced - synced via astrona-ats-003-lab-042-server, Leap status Normal, Stratum $stratum"
  exit 0
else
  echo "FAIL: client-synced - Leap status '$leap', Stratum '$stratum' (expected Normal / 2-15, one hop above the server)"
  exit 1
fi
