#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Checks that resolved holds no DNS server for dhcp0.
set -u

if ! ip -br link show dhcp0 >/dev/null 2>&1; then
  echo "FAIL: dns - dhcp0 does not exist"
  exit 1
fi
out="$(resolvectl dns dhcp0 2>&1)"
servers="${out#*:}"
if echo "$servers" | grep -Eq '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then
  echo "FAIL: dns - dhcp0 still has a DNS server: $servers"
  exit 1
fi
echo "PASS: dns (no DNS server from the lease)"
exit 0
ASTRONA_STUDENT_SCRIPT
