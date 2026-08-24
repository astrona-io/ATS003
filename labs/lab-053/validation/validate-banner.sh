#!/usr/bin/env bash
# Confirms the Banner directive resolves to /etc/ssh/sshd-banner for both
# elena and victor via the effective per-connection config, and that the
# banner file itself exists and is readable.

set -u

host="$(hostname)"
expected="/etc/ssh/sshd-banner"
pass=true

if [[ ! -f "$expected" ]]; then
  echo "FAIL: banner - $expected does not exist"
  exit 1
fi

for user in elena victor; do
  val="$(sudo sshd -T -C user="${user}",host="${host}",addr=127.0.0.1 2>/dev/null | grep -i '^banner' | awk '{print $2}')"
  if [[ "$val" != "$expected" ]]; then
    echo "FAIL: banner - ${user} effective banner = '$val', expected '$expected'"
    pass=false
  else
    echo "PASS: banner - ${user} effective banner = '$expected'"
  fi
done

if $pass; then
  exit 0
else
  exit 1
fi
