#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks /proc/net/bonding/bond0 reports a real Currently Active Slave

set -u

path="/proc/net/bonding/bond0"

if [[ ! -f "$path" ]]; then
  echo "FAIL: bond-active-slave - $path does not exist (bond0 not created)"
  exit 1
fi

active="$(grep 'Currently Active Slave:' "$path" | awk -F': ' '{print $2}')"

if [[ -z "$active" || "$active" == "None" ]]; then
  echo "FAIL: bond-active-slave - Currently Active Slave is '${active:-empty}', expected dummy1 or dummy2"
  exit 1
fi

if [[ "$active" != "dummy1" && "$active" != "dummy2" ]]; then
  echo "FAIL: bond-active-slave - Currently Active Slave is '$active', expected dummy1 or dummy2"
  exit 1
fi

echo "PASS: bond-active-slave (Currently Active Slave = $active)"
exit 0
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
