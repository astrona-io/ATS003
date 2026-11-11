#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Checks the local forward 9090 -> 127.0.0.1:8081 through ssh.
set -u

listener="$(sudo ss -tlnp 'sport = :9090' 2>/dev/null | grep -F 'ssh')"
if [[ -z "$listener" ]]; then
  echo "FAIL: tunnel - no ssh process listens on port 9090"
  exit 1
fi

if curl -s -m 5 http://127.0.0.1:9090/ | grep -q 'station data online'; then
  echo "PASS: tunnel (ssh listens on 9090 and the web service answers through it)"
  exit 0
fi

echo "FAIL: tunnel - port 9090 is open but the web service did not answer through it"
exit 1
ASTRONA_STUDENT_SCRIPT
