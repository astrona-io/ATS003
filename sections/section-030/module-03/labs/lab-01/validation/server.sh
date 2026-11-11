#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
set -eu
for port in 8080 8081; do
  if ! curl --noproxy '*' -fsS --max-time 3 "http://172.20.20.20:$port/" >/dev/null; then
    echo "FAIL: control listener $port is down"; exit 1
  fi
done
echo 'PASS: both control listeners respond on the server'
ASTRONA_STUDENT_SCRIPT
