#!/usr/bin/env bash
# Checks that TCP port 5000 is dropped in the inet filter input chain
# (live nftables state, not an artificial output file).

set -u

input_chain="$(sudo nft list chain inet filter input 2>/dev/null)"

if [[ -z "$input_chain" ]]; then
  echo "FAIL: port-5000-drop - table inet filter, chain input does not exist"
  exit 1
fi

if echo "$input_chain" | grep -Eq 'tcp dport 5000[[:space:]]+drop'; then
  echo "PASS: port-5000-drop (tcp dport 5000 drop found in inet filter input)"
  exit 0
else
  echo "FAIL: port-5000-drop - no 'tcp dport 5000 drop' rule found in inet filter input"
  exit 1
fi
