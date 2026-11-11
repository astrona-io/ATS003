#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Checks the resolved.conf drop-in for the server and the search domain.
set -u

files=$(sudo find /etc/systemd/resolved.conf.d -maxdepth 1 -name '*.conf' 2>/dev/null)
if [[ -z "$files" ]]; then
  echo "FAIL: dropin - no .conf file in /etc/systemd/resolved.conf.d"
  exit 1
fi

content="$(sudo cat $files)"

if ! echo "$content" | grep -Eq '^[[:space:]]*DNS=.*10\.55\.0\.53'; then
  echo "FAIL: dropin - no 'DNS=10.55.0.53' line found in the drop-in files"
  exit 1
fi

if ! echo "$content" | grep -Eq '^[[:space:]]*Domains=.*lab\.example'; then
  echo "FAIL: dropin - no 'Domains=lab.example' line found in the drop-in files"
  exit 1
fi

echo "PASS: dropin (DNS=10.55.0.53 and Domains=lab.example are set)"
exit 0
ASTRONA_STUDENT_SCRIPT
