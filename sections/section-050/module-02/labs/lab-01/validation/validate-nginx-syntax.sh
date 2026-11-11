#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Checks that the full merged nginx configuration (existing apps + the
# student's new file) is syntactically valid.

set -u

out="$(sudo nginx -t 2>&1)"
rc=$?

if [[ $rc -eq 0 ]]; then
  echo "PASS: nginx config syntax - $out"
  exit 0
else
  echo "FAIL: nginx config syntax - nginx -t reported errors:"
  echo "$out"
  exit 1
fi
ASTRONA_STUDENT_SCRIPT
