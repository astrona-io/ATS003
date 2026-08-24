#!/usr/bin/env bash
# Checks that all four required sources use maxpoll 10 (2^10 = 1024s, the
# closest power-of-two chrony can express to the requested 1000s).

set -u

conf=""
for c in /etc/chrony/chrony.conf /etc/chrony.conf; do
  if [[ -f "$c" ]]; then
    conf="$c"
    break
  fi
done

if [[ -z "$conf" ]]; then
  echo "FAIL: maxpoll - no chrony.conf found (checked /etc/chrony/chrony.conf, /etc/chrony.conf)"
  exit 1
fi

hosts=(0.pool.ntp.org 1.pool.ntp.org ntp.ubuntu.com 0.debian.pool.ntp.org)
bad=()

for host in "${hosts[@]}"; do
  line="$(grep -E "^[[:space:]]*(server|pool)[[:space:]]+${host//./\\.}([[:space:]]|\$)" "$conf")"
  if [[ -z "$line" ]]; then
    bad+=("$host (not configured)")
  elif ! echo "$line" | grep -Eq 'maxpoll[[:space:]]+10\b'; then
    bad+=("$host (maxpoll 10 missing)")
  fi
done

if [[ ${#bad[@]} -eq 0 ]]; then
  echo "PASS: maxpoll 10 (1024s) set on all four required sources in $conf"
  exit 0
else
  echo "FAIL: maxpoll - ${bad[*]}"
  exit 1
fi
