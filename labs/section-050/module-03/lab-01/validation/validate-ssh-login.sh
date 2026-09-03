#!/usr/bin/env bash
# Confirms real SSH login behavior matches the hardened config end-to-end:
# elena can still authenticate with a password, victor cannot. This checks
# actual connectivity (ssh -p / live login), not just the config file.

set -u

opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o PreferredAuthentications=password -o PubkeyAuthentication=no)

if ! command -v sshpass >/dev/null 2>&1; then
  echo "FAIL: ssh-login - sshpass is not installed, cannot run a live login check"
  exit 1
fi

pass=true

if sshpass -p 'elena' ssh "${opts[@]}" elena@localhost true 2>/tmp/validate-elena-ssh.log; then
  echo "PASS: ssh-login-elena (password login succeeded)"
else
  echo "FAIL: ssh-login-elena - password login failed: $(tail -1 /tmp/validate-elena-ssh.log 2>/dev/null)"
  pass=false
fi

if sshpass -p 'victor' ssh "${opts[@]}" victor@localhost true 2>/tmp/validate-victor-ssh.log; then
  echo "FAIL: ssh-login-victor - password login unexpectedly succeeded"
  pass=false
else
  echo "PASS: ssh-login-victor (password login correctly rejected)"
fi

if $pass; then
  exit 0
else
  exit 1
fi
