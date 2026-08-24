#!/usr/bin/env bash
# Checks br0 and bond0 are defined in persistent config (Netplan or
# NetworkManager), not just live kernel state that would vanish on reboot.

set -u

netplan_br0=""
netplan_bond0=""
if compgen -G "/etc/netplan/*.yaml" > /dev/null 2>&1; then
  netplan_br0="$(grep -rl 'br0:' /etc/netplan/*.yaml 2> /dev/null || true)"
  netplan_bond0="$(grep -rl 'bond0:' /etc/netplan/*.yaml 2> /dev/null || true)"
fi

nm_br0=""
nm_bond0=""
if command -v nmcli &> /dev/null; then
  nm_br0="$(nmcli -t -f NAME,TYPE con show 2> /dev/null | grep -i 'bridge' || true)"
  nm_bond0="$(nmcli -t -f NAME,TYPE con show 2> /dev/null | grep -i 'bond' || true)"
fi

if [[ -z "$netplan_br0" && -z "$nm_br0" ]]; then
  echo "FAIL: persistence - br0 not found in Netplan (/etc/netplan/*.yaml) or NetworkManager connections"
  exit 1
fi

if [[ -z "$netplan_bond0" && -z "$nm_bond0" ]]; then
  echo "FAIL: persistence - bond0 not found in Netplan (/etc/netplan/*.yaml) or NetworkManager connections"
  exit 1
fi

echo "PASS: persistence (br0 and bond0 both found in persistent config)"
exit 0
