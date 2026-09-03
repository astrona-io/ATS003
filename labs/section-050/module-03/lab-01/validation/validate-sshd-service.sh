#!/usr/bin/env bash
# Confirms the sshd/ssh service is active (real live system state, not a
# recorded output file).

set -u

if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
  echo "PASS: sshd-service (ssh/sshd is active)"
  exit 0
else
  echo "FAIL: sshd-service - neither the sshd nor ssh unit is active"
  exit 1
fi
