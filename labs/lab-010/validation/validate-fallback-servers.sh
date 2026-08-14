#!/usr/bin/env bash
# Checks that ntp.ubuntu.com and 0.debian.pool.ntp.org are configured as
# chrony sources (server or pool directive) in the live chrony.conf.

set -u

conf=""
for c in /etc/chrony/chrony.conf /etc/chrony.conf; do
  if [[ -f "$c" ]]; then
    conf="$c"
    break
  fi
done

if [[ -z "$conf" ]]; then
  echo "FAIL: fallback servers - no chrony.conf found (checked /etc/chrony/chrony.conf, /etc/chrony.conf)"
  exit 1
fi

missing=()
for host in ntp.ubuntu.com 0.debian.pool.ntp.org; do
  if ! grep -Eq "^[[:space:]]*(server|pool)[[:space:]]+${host//./\\.}([[:space:]]|\$)" "$conf"; then
    missing+=("$host")
  fi
done

if [[ ${#missing[@]} -eq 0 ]]; then
  echo "PASS: fallback servers configured in $conf (ntp.ubuntu.com, 0.debian.pool.ntp.org)"
  exit 0
else
  echo "FAIL: fallback servers - missing from $conf: ${missing[*]}"
  exit 1
fi
