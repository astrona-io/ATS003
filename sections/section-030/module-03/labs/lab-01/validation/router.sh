#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
set -u
if test "$(sysctl -n net.ipv4.ip_forward)" != 1; then
  echo 'FAIL: IPv4 forwarding is disabled'; exit 1
fi
if ! sudo systemctl is-enabled --quiet nftables; then
  echo 'FAIL: nftables must be enabled for the next boot'; exit 1
fi
if ! sudo nft -c -f /etc/nftables.conf; then
  echo 'FAIL: persistent nftables configuration is invalid'; exit 1
fi
echo 'PASS: forwarding active and persistent firewall load configured'
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
