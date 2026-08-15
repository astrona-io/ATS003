#!/usr/bin/env bash
# Checks that chrony.conf has an active `allow` directive permitting
# the internal subnet (192.168.10.0/24) - the single line that turns
# this chronyd from client-only into also serving time to that subnet.

set -u

conf=""
for c in /etc/chrony/chrony.conf /etc/chrony.conf; do
  if [[ -f "$c" ]]; then
    conf="$c"
    break
  fi
done

if [[ -z "$conf" ]]; then
  echo "FAIL: allow-directive - no chrony.conf found (checked /etc/chrony/chrony.conf, /etc/chrony.conf)"
  exit 1
fi

match="$(grep -E '^[[:space:]]*allow[[:space:]]+192\.168\.10\.0/24[[:space:]]*$' "$conf" || true)"

if [[ -n "$match" ]]; then
  echo "PASS: allow-directive ($conf contains '$match')"
  exit 0
else
  echo "FAIL: allow-directive - no active 'allow 192.168.10.0/24' line found in $conf"
  exit 1
fi
