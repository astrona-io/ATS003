#!/usr/bin/env bash
# Checks that the secondary IPv4/IPv6 addresses are declared in a
# persistent config (Netplan or NetworkManager), not only applied live
# with `ip addr add`, so they survive a reboot.

set -u

iface="$(ip -o -4 route show to default | awk '{print $5}')"
if [[ -z "$iface" ]]; then
  echo "FAIL: persistence - could not detect primary interface (no default route)"
  exit 1
fi

ipv4_found=0
ipv6_found=0

# Netplan path: search all netplan YAML files for the addresses.
if compgen -G "/etc/netplan/*.yaml" > /dev/null 2>&1; then
  if grep -rq "192.168.10.71" /etc/netplan/*.yaml 2>/dev/null; then
    ipv4_found=1
  fi
  if grep -rq "fd00:10::70" /etc/netplan/*.yaml 2>/dev/null; then
    ipv6_found=1
  fi
fi

# NetworkManager path: search the connection profile for the interface.
if command -v nmcli >/dev/null 2>&1; then
  nm_conf="$(nmcli -t -f ipv4.addresses,ipv6.addresses con show "$iface" 2>/dev/null || true)"
  if echo "$nm_conf" | grep -q "192.168.10.71"; then
    ipv4_found=1
  fi
  if echo "$nm_conf" | grep -q "fd00:10::70"; then
    ipv6_found=1
  fi
fi

if [[ "$ipv4_found" -eq 1 && "$ipv6_found" -eq 1 ]]; then
  echo "PASS: persistence (192.168.10.71 and fd00:10::70 both declared in persistent config)"
  exit 0
else
  echo "FAIL: persistence - ipv4_declared=$ipv4_found ipv6_declared=$ipv6_found (checked /etc/netplan/*.yaml and nmcli con show $iface)"
  exit 1
fi
