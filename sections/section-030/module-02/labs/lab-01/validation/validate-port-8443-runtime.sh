#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Confirms 8443/tcp is allowed in the public zone's runtime (live)
# configuration.

set -u

ports="$(sudo firewall-cmd --zone=public --list-ports 2>/dev/null)"

if grep -qw "8443/tcp" <<< "$ports"; then
  echo "PASS: port-8443-runtime (8443/tcp present in runtime ports: '$ports')"
  exit 0
else
  echo "FAIL: port-8443-runtime - 8443/tcp not in runtime ports: '$ports'"
  exit 1
fi
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
