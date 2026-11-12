#!/usr/bin/env bash
set -euo pipefail
sudo networkctl reconfigure dhcp0
for attempt in $(seq 1 60); do
  if ip -4 -o addr show dhcp0 | grep -q '10.77.0.1[0-4][0-9]/'; then exit 0; fi
  sleep 1
done
sudo networkctl status dhcp0 dhcpsrv0
sudo journalctl -u systemd-networkd --no-pager -n 50
exit 1
