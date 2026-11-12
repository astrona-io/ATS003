#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks that lab0 is up and still has its address.
set -u

line="$(ip -br addr show lab0 2>/dev/null)"
if [[ -z "$line" ]]; then
  echo "FAIL: link - the interface lab0 does not exist"
  exit 1
fi

flags="$(ip -o link show lab0 | sed -n 's/.*<\([^>]*\)>.*/\1/p')"
if ! echo ",$flags," | grep -q ',UP,'; then
  echo "FAIL: link - lab0 is not up (flags: ${flags})"
  exit 1
fi

if ! echo "$line" | grep -q '10\.66\.0\.10/24'; then
  echo "FAIL: link - lab0 has lost the address 10.66.0.10/24"
  exit 1
fi

echo "PASS: link (lab0 is up with 10.66.0.10/24)"
exit 0
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
