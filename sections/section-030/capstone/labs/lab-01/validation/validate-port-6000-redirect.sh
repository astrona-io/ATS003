#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
set -eu
fail() { echo "FAIL: $*"; exit 1; }
[ "$(sudo ip netns exec nft-client curl --noproxy '*' -fsS --max-time 3 http://192.168.10.1:6000/)" = listener-6001 ] || fail 'port 6000 did not reach the port 6001 listener'
echo 'PASS: expected packet behavior observed'
ASTRONA_STUDENT_SCRIPT
