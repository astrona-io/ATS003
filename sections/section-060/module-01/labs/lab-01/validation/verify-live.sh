#!/usr/bin/env bash
set -euo pipefail
ip -o -4 address show nm0 | awk '{print $4}' | grep -qx '192.168.120.50/24' || { echo 'FAIL: live - correct address is not active'; exit 1; }
if ip -o -4 address show nm0 | grep -q '192.168.120.99/24'; then echo 'FAIL: live - stale address remains'; exit 1; fi
nmcli -t -f NAME,DEVICE connection show --active | grep -qx 'lab-static:nm0' || { echo 'FAIL: live - lab-static is not active on nm0'; exit 1; }
expected=$(sudo cat /var/lib/course/management-interface)
ip -4 route show default | awk '{print $5}' | grep -qx "$expected" || { echo 'FAIL: management default route changed'; exit 1; }
echo 'PASS: active profile and management route'
