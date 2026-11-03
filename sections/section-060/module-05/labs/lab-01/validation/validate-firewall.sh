#!/usr/bin/env bash
# Checks that no live nftables rule drops tcp port 8443.
set -u

if ! command -v nft >/dev/null 2>&1; then
  echo "FAIL: firewall - nft is not installed, cannot check ruleset"
  exit 1
fi

if sudo nft list ruleset 2>/dev/null | grep -Eq 'tcp dport 8443.*(drop|reject)'; then
  echo "FAIL: firewall - a rule still drops or rejects tcp dport 8443"
  exit 1
fi

echo "PASS: firewall (no rule drops tcp dport 8443)"
exit 0
