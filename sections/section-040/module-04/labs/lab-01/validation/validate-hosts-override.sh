#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Checks the /etc/hosts override and that the DNS server itself is unchanged.
set -u

local_answer="$(getent hosts www.lab.example 2>/dev/null | awk '{print $1; exit}')"
if [[ "$local_answer" != "198.51.100.80" ]]; then
  echo "FAIL: hosts-override - getent hosts www.lab.example returned '${local_answer:-nothing}' instead of 198.51.100.80"
  exit 1
fi

server_answer="$(dig +short +time=3 +tries=1 @10.55.0.53 www.lab.example 2>/dev/null | head -n1)"
if [[ "$server_answer" != "203.0.113.10" ]]; then
  echo "FAIL: hosts-override - the DNS server answered '${server_answer:-nothing}' instead of 203.0.113.10 (do not change the zone)"
  exit 1
fi

echo "PASS: hosts-override (/etc/hosts gives 198.51.100.80, the server still gives 203.0.113.10)"
exit 0
ASTRONA_STUDENT_SCRIPT
