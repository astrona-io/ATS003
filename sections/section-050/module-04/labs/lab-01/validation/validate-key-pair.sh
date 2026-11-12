#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Checks that cadet owns an ed25519 key pair and the private key is private.
set -u

key="/home/cadet/.ssh/id_ed25519"

if ! sudo test -f "$key" || ! sudo test -f "${key}.pub"; then
  echo "FAIL: key-pair - ${key} or ${key}.pub is missing"
  exit 1
fi

if ! sudo grep -q '^ssh-ed25519 ' "${key}.pub"; then
  echo "FAIL: key-pair - ${key}.pub is not an ed25519 public key"
  exit 1
fi

mode="$(sudo stat -c '%a' "$key")"
if [[ "${mode: -2}" != "00" ]]; then
  echo "FAIL: key-pair - private key mode is ${mode}, group and others must have no access"
  exit 1
fi

echo "PASS: key-pair (ed25519 key pair, private key mode ${mode})"
exit 0
ASTRONA_STUDENT_SCRIPT
