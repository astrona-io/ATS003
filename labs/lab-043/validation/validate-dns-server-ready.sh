#!/usr/bin/env bash
# Confirms this VM is actually serving as the internal DNS server:
# bind9/named is active, and both zones loaded without error.

set -u

if ! systemctl is-active --quiet named 2>/dev/null && ! systemctl is-active --quiet bind9 2>/dev/null; then
  echo "FAIL: dns-server-ready - neither named nor bind9 service is active"
  exit 1
fi

if ! sudo named-checkzone internal.example.com /etc/bind/zones/db.internal.example.com >/dev/null 2>&1; then
  echo "FAIL: dns-server-ready - forward zone internal.example.com fails named-checkzone"
  exit 1
fi

if ! sudo named-checkzone 10.168.192.in-addr.arpa /etc/bind/zones/db.192.168.10 >/dev/null 2>&1; then
  echo "FAIL: dns-server-ready - reverse zone 10.168.192.in-addr.arpa fails named-checkzone"
  exit 1
fi

if ! dig @127.0.0.1 +short data-001.internal.example.com A 2>/dev/null | grep -q '192\.168\.10\.80'; then
  echo "FAIL: dns-server-ready - local query for data-001.internal.example.com did not return 192.168.10.80"
  exit 1
fi

echo "PASS: dns-server-ready (bind9/named active, both zones valid, answering queries)"
exit 0
