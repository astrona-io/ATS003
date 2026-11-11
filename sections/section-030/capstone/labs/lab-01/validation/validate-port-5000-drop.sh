#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
set -eu
fail() { echo "FAIL: $*"; exit 1; }
sudo ss -ltn | grep -Eq ':5000[[:space:]]' || fail 'port 5000 listener unavailable'
[ "$(sudo ip netns exec nft-client curl --noproxy '*' -fsS --max-time 3 http://192.168.10.1:6001/)" = listener-6001 ] || fail 'control traffic to port 6001 failed'
status=0
sudo ip netns exec nft-client curl --noproxy '*' -fsS --max-time 2 http://192.168.10.1:5000/ >/dev/null 2>&1 || status=$?
[ "$status" -eq 28 ] || fail "port 5000 must drop traffic (curl exit $status)"
echo 'PASS: expected packet behavior observed'
ASTRONA_STUDENT_SCRIPT
