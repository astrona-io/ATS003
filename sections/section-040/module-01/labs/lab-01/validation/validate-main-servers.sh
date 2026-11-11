#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks that 0.pool.ntp.org and 1.pool.ntp.org are configured as chrony
# sources (server or pool directive) in the live chrony.conf.

set -u

conf=""
for c in /etc/chrony/chrony.conf /etc/chrony.conf; do
  if [[ -f "$c" ]]; then
    conf="$c"
    break
  fi
done

if [[ -z "$conf" ]]; then
  echo "FAIL: main servers - no chrony.conf found (checked /etc/chrony/chrony.conf, /etc/chrony.conf)"
  exit 1
fi

missing=()
for host in 0.pool.ntp.org 1.pool.ntp.org; do
  if ! grep -Eq "^[[:space:]]*(server|pool)[[:space:]]+${host//./\\.}([[:space:]]|\$)" "$conf"; then
    missing+=("$host")
  fi
done

if [[ ${#missing[@]} -eq 0 ]]; then
  echo "PASS: main servers configured in $conf (0.pool.ntp.org, 1.pool.ntp.org)"
  exit 0
else
  echo "FAIL: main servers - missing from $conf: ${missing[*]}"
  exit 1
fi
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
