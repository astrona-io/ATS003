#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Confirms https is allowed in the public zone's permanent (saved)
# configuration, so it survives a reload/reboot.

set -u

services="$(sudo firewall-cmd --zone=public --list-services --permanent 2>/dev/null)"

if grep -qw "https" <<< "$services"; then
  echo "PASS: https-permanent (https present in permanent services: '$services')"
  exit 0
else
  echo "FAIL: https-permanent - https not in permanent services: '$services'"
  exit 1
fi
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
