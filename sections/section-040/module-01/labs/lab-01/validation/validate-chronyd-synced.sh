#!/usr/bin/env bash
# Checks that chronyd picked up the edited config (reload/restart happened)
# and is actively disciplining the clock, per `chronyc tracking`.

set -u

if ! systemctl is-active --quiet chrony 2>/dev/null && ! systemctl is-active --quiet chronyd 2>/dev/null; then
  echo "FAIL: chrony sync - chronyd service is not active"
  exit 1
fi

tracking="$(chronyc tracking 2>/dev/null)"

if [[ -z "$tracking" ]]; then
  echo "FAIL: chrony sync - chronyc tracking returned no output"
  exit 1
fi

leap="$(echo "$tracking" | awk -F: '/Leap status/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"

if [[ "$leap" == "Normal" ]]; then
  echo "PASS: chrony sync - chronyd active, Leap status: Normal"
  exit 0
else
  echo "FAIL: chrony sync - Leap status is '$leap', expected 'Normal'"
  exit 1
fi
