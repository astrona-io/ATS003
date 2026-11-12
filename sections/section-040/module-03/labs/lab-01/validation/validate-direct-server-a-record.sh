#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks a direct query against the dns VM's real address (bypassing
# /etc/resolv.conf entirely) returns the same A record as the system
# resolver, confirming the record itself -- not the resolver -- is
# correct. Two genuinely independent lookup paths, not the same box
# answering twice.

set -u

dns_host="192.168.10.53"
dns_ip="192.168.10.53"

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
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
