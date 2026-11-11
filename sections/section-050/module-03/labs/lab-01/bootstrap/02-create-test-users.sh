#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Bootstrap: creates the elena and victor test accounts the scenario expects
# to already exist. Both authenticate with a password only (no SSH key),
# matching "Passwords are their username and shouldn't be changed."

set -eu

for user in elena victor; do
  if ! id -u "$user" >/dev/null 2>&1; then
    sudo useradd -m -s /bin/bash "$user"
  fi
  echo "${user}:${user}" | sudo chpasswd
  sudo passwd -u "$user" >/dev/null 2>&1 || true
done
ASTRONA_STUDENT_SCRIPT
