#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Checks the client's chrony.conf points at the internal server
# (192.168.10.123) instead of the public NTP pool.

set -u

conf=""
for c in /etc/chrony/chrony.conf /etc/chrony.conf; do
  if [[ -f "$c" ]]; then
    conf="$c"
    break
  fi
done

if [[ -z "$conf" ]]; then
  echo "FAIL: client-source - no chrony.conf found (checked /etc/chrony/chrony.conf, /etc/chrony.conf)"
  exit 1
fi

server_line="$(grep -E '^[[:space:]]*server[[:space:]]+192.168.10.123([[:space:]]|$)' "$conf" || true)"
public_pool="$(grep -E '^[[:space:]]*(server|pool)[[:space:]]+.*(pool\.ntp\.org|ntp\.ubuntu\.com|debian\.pool\.ntp\.org)' "$conf" || true)"

if [[ -z "$server_line" ]]; then
  echo "FAIL: client-source - no active 'server 192.168.10.123' line found in $conf"
  exit 1
fi

if [[ -n "$public_pool" ]]; then
  echo "FAIL: client-source - $conf still has an active public pool/server line ('$public_pool'); replace it, don't just add alongside"
  exit 1
fi

echo "PASS: client-source ($conf points at 192.168.10.123, public pool lines removed)"
exit 0
ASTRONA_STUDENT_SCRIPT
