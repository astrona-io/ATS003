#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
set -eu
fail() { echo "FAIL: $*"; exit 1; }
[ "$(curl --noproxy '*' -fsS --max-time 3 http://192.168.10.80:9000/)" = egress-listener ] || fail 'egress control listener unavailable'
status=0
curl --noproxy '*' -fsS --max-time 2 http://192.168.10.70:9000/ >/dev/null 2>&1 || status=$?
[ "$status" -eq 28 ] || fail "egress to 192.168.10.70 must be dropped (curl exit $status)"
echo 'PASS: expected packet behavior observed'
ASTRONA_STUDENT_SCRIPT
