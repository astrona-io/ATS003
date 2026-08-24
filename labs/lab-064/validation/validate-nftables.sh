#!/usr/bin/env bash
# Checks that the nftables rule dropping traffic to port 8080 (deliberately
# created at bootstrap) has been removed from the live ruleset.

set -u

if ! command -v nft >/dev/null 2>&1; then
  echo "FAIL: nftables - nft is not installed, cannot check ruleset"
  exit 1
fi

ruleset="$(sudo nft list ruleset 2>/dev/null)"

if echo "$ruleset" | grep -q 'tcp dport 8080 drop'; then
  echo "FAIL: nftables - a 'tcp dport 8080 drop' rule is still present in the live ruleset"
  exit 1
fi

echo "PASS: nftables (no 'tcp dport 8080 drop' rule remains in the live ruleset)"
exit 0
