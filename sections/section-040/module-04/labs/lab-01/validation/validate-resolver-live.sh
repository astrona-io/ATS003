#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks that the running resolver knows the lab server.
set -u

if ! systemctl is-active --quiet systemd-resolved; then
  echo "FAIL: resolver-live - systemd-resolved is not running"
  exit 1
fi

if resolvectl status 2>/dev/null | grep -q '10\.55\.0\.53'; then
  echo "PASS: resolver-live (resolvectl status reports 10.55.0.53)"
  exit 0
fi

echo "FAIL: resolver-live - resolvectl status does not list 10.55.0.53 (restart systemd-resolved after writing the drop-in)"
exit 1
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
