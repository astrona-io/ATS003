#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
set -u
peer=$(curl --noproxy '*' --connect-timeout 2 --max-time 4 -fsS http://172.20.20.20:8080/ 2>/dev/null) || {
  echo 'FAIL: allowed HTTP request does not cross the router'; exit 1;
}
if test "$peer" != 172.20.20.1; then
  echo "FAIL: server sees $peer instead of the masqueraded router address"; exit 1
fi
status=0
curl --noproxy '*' --connect-timeout 2 --max-time 4 -fsS http://172.20.20.20:8081/ >/dev/null 2>&1 || status=$?
if test "$status" != 28; then
  echo "FAIL: forbidden TCP port must be dropped (curl exit $status)"; exit 1
fi
echo 'PASS: routed HTTP is masqueraded and the forbidden port is dropped'
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
