#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Bootstrap: firewalld ships in the base LFCS image; this disables the
# conflicting ufw firewall before it is ever started.
#
# The base image is Ubuntu, which normally ships ufw (itself a wrapper
# around nftables) rather than firewalld. Having both manage the same
# nftables/iptables backend at once produces confusing, contradictory
# rule sets, so ufw is stopped and disabled before firewalld is ever
# started.

set -eu

if command -v ufw >/dev/null 2>&1; then
  if sudo ufw status | grep -qi "^Status: active"; then
    sudo ufw --force disable
  fi
  sudo systemctl disable --now ufw.service 2>/dev/null || true
fi
ASTRONA_STUDENT_SCRIPT
