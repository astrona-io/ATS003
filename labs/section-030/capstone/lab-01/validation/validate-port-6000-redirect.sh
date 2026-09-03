#!/usr/bin/env bash
# Checks that TCP port 6000 is redirected to local port 6001 via the
# nat table's prerouting chain, and that something is actually
# listening on 6001 so the redirect is functionally meaningful.

set -u

nat_prerouting="$(sudo nft list chain ip nat prerouting 2>/dev/null)"

if [[ -z "$nat_prerouting" ]]; then
  echo "FAIL: port-6000-redirect - table ip nat, chain prerouting does not exist"
  exit 1
fi

if ! echo "$nat_prerouting" | grep -q 'type nat hook prerouting'; then
  echo "FAIL: port-6000-redirect - chain prerouting is not attached to hook prerouting"
  exit 1
fi

if ! echo "$nat_prerouting" | grep -Eq 'tcp dport 6000[[:space:]]+redirect to :?6001'; then
  echo "FAIL: port-6000-redirect - no 'tcp dport 6000 redirect to :6001' rule found"
  exit 1
fi

if ! sudo ss -tulpn 2>/dev/null | grep -q ':6001[[:space:]]'; then
  echo "FAIL: port-6000-redirect - nothing is listening on local port 6001"
  exit 1
fi

echo "PASS: port-6000-redirect (redirect rule present and 6001 has a listener)"
exit 0
