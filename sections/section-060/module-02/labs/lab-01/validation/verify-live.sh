#!/usr/bin/env bash
set -euo pipefail
actual=$(ip -o -4 address show np0 scope global | awk '{print $4}')
if [ "$actual" != '192.168.130.50/24' ]; then echo 'FAIL: live - np0 must have only 192.168.130.50/24'; exit 1; fi
expected=$(sudo cat /var/lib/course/management-interface)
ip -4 route show default | awk '{print $5}' | grep -qx "$expected" || { echo 'FAIL: management default route changed'; exit 1; }
echo 'PASS: live Netplan address and management route'
