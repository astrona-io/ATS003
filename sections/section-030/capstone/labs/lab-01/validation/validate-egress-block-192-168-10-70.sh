#!/usr/bin/env bash
# Checks that outgoing traffic to 192.168.10.70 is dropped in the
# inet filter output chain (not input, which would be the wrong
# direction).

set -u

output_chain="$(sudo nft list chain inet filter output 2>/dev/null)"

if [[ -z "$output_chain" ]]; then
  echo "FAIL: egress-block-192.168.10.70 - table inet filter, chain output does not exist"
  exit 1
fi

if echo "$output_chain" | grep -Eq 'ip daddr 192\.168\.10\.70[[:space:]]+drop'; then
  echo "PASS: egress-block-192.168.10.70 (egress to 192.168.10.70 is dropped in output chain)"
  exit 0
else
  echo "FAIL: egress-block-192.168.10.70 - no 'ip daddr 192.168.10.70 drop' rule found in output chain"
  exit 1
fi
