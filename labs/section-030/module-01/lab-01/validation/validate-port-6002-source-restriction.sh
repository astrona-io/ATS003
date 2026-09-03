#!/usr/bin/env bash
# Checks that port 6002 is accepted from 192.168.10.80 and dropped for
# everyone else, with the accept rule ordered before the catch-all
# drop -- nftables evaluates top-to-bottom, so a misordered drop would
# silently shadow the accept even though both rules technically exist.

set -u

chain="$(sudo nft list chain inet filter input 2>/dev/null)"

if [[ -z "$chain" ]]; then
  echo "FAIL: port-6002-source-restriction - table inet filter, chain input does not exist"
  exit 1
fi

accept_lineno="$(echo "$chain" | grep -nE 'tcp dport 6002.*192\.168\.10\.80.*accept' | head -1 | cut -d: -f1)"
drop_lineno="$(echo "$chain" | grep -nE 'tcp dport 6002[[:space:]]+drop' | head -1 | cut -d: -f1)"

if [[ -z "$accept_lineno" ]]; then
  echo "FAIL: port-6002-source-restriction - no accept rule for 192.168.10.80 on port 6002"
  exit 1
fi

if [[ -z "$drop_lineno" ]]; then
  echo "FAIL: port-6002-source-restriction - no catch-all drop rule for port 6002"
  exit 1
fi

if (( accept_lineno < drop_lineno )); then
  echo "PASS: port-6002-source-restriction (accept for 192.168.10.80 precedes catch-all drop)"
  exit 0
else
  echo "FAIL: port-6002-source-restriction - drop rule for 6002 precedes (or is not after) the 192.168.10.80 accept rule, so the accept would be shadowed"
  exit 1
fi
