#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Checks that dhcp0 holds a dynamic address from the DHCP pool.
set -u

line="$(ip -4 -o addr show dev dhcp0 2>/dev/null)"
addr="$(echo "$line" | grep -oE '10\.77\.0\.[0-9]+' | head -n1)"
if [[ -z "$addr" ]]; then
  echo "FAIL: lease - dhcp0 has no 10.77.0.x address"
  exit 1
fi
last="${addr##*.}"
if (( last < 100 || last > 149 )); then
  echo "FAIL: lease - $addr is outside the pool 10.77.0.100-149 (a static address?)"
  exit 1
fi
if ! echo "$line" | grep -q 'dynamic'; then
  echo "FAIL: lease - $addr is not marked dynamic, so it did not come from DHCP"
  exit 1
fi
echo "PASS: lease (dhcp0 holds $addr from DHCP)"
exit 0
ASTRONA_STUDENT_SCRIPT
