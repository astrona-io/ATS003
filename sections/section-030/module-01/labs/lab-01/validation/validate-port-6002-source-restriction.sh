#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
set -eu
fail() { echo "FAIL: $*"; exit 1; }
[ "$(sudo ip netns exec nft-client curl --noproxy '*' --interface 192.168.10.80 -fsS --max-time 3 http://192.168.10.1:6002/)" = listener-6002 ] || fail 'allowed source cannot reach port 6002'
status=0
sudo ip netns exec nft-client curl --noproxy '*' --interface 192.168.10.81 -fsS --max-time 2 http://192.168.10.1:6002/ >/dev/null 2>&1 || status=$?
[ "$status" -eq 28 ] || fail "untrusted source must be dropped (curl exit $status)"
echo 'PASS: expected packet behavior observed'
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
