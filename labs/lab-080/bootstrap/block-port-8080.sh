#!/usr/bin/env bash
# Bootstrap: deliberately blocks tcp/8080 with an nftables rule so the
# student has a real, reproducible firewall problem to diagnose and fix.
# This mirrors the lab scenario exactly: the app is listening correctly,
# but an nftables rule is silently dropping traffic to it.

set -eu

sudo systemctl enable --now nftables 2>/dev/null || true

# Create the filter table/chain if they don't already exist.
sudo nft list table inet filter >/dev/null 2>&1 || sudo nft add table inet filter
sudo nft list chain inet filter input >/dev/null 2>&1 || \
  sudo nft add chain inet filter input '{ type filter hook input priority filter ; policy accept ; }'

# Add the drop rule only if an equivalent rule isn't already present, so
# re-running this script doesn't stack duplicate rules.
if ! sudo nft list chain inet filter input | grep -q 'tcp dport 8080 drop'; then
  sudo nft add rule inet filter input tcp dport 8080 drop
fi

# Persist the (broken) ruleset, exactly like a real misconfiguration would
# survive a reboot until the student fixes and re-persists it.
sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
