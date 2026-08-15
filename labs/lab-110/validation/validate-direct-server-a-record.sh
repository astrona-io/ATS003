#!/usr/bin/env bash
# Checks a direct query against the dns VM's real address (bypassing
# /etc/resolv.conf entirely) returns the same A record as the system
# resolver, confirming the record itself -- not the resolver -- is
# correct. Two genuinely independent lookup paths, not the same box
# answering twice.

set -u

dns_host="astrona-ats-003-lab-110-dns"
dns_ip="$(getent hosts "$dns_host" 2>/dev/null | awk '{print $1}' | head -n1)"

if [[ -z "$dns_ip" ]]; then
  echo "FAIL: direct-server A record - could not resolve $dns_host to an address"
  exit 1
fi

expected="192.168.10.80"
actual="$(dig "@${dns_ip}" +short data-001.internal.example.com A 2>/dev/null | tail -n1)"

if [[ "$actual" == "$expected" ]]; then
  echo "PASS: direct-server A record (@${dns_ip} data-001.internal.example.com = '$actual')"
  exit 0
else
  echo "FAIL: direct-server A record - @${dns_ip} data-001.internal.example.com = '$actual', expected '$expected'"
  exit 1
fi
