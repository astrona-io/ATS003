#!/usr/bin/env bash
# Bootstrap: sets the pre-hardening sshd_config baseline the scenario expects
# the trainee to change (password auth and X11 forwarding both enabled, no
# Match blocks yet). This never touches PubkeyAuthentication or any other
# directive the astrona admin user's key-based access depends on, so the
# hardening steps performed later in this lab (which only ever scope
# PasswordAuthentication/X11Forwarding/Banner globally or via `Match User
# elena`/`Match User elena,victor`) can never lock out the account actually
# running this lab.

set -eu

CONFIG=/etc/ssh/sshd_config

set_directive() {
  local key="$1" value="$2"
  if sudo grep -qE "^[[:space:]]*${key}[[:space:]]" "$CONFIG"; then
    sudo sed -i -E "s|^[[:space:]]*${key}[[:space:]].*|${key} ${value}|" "$CONFIG"
  elif sudo grep -qE "^[[:space:]]*#[[:space:]]*${key}[[:space:]]" "$CONFIG"; then
    sudo sed -i -E "s|^[[:space:]]*#[[:space:]]*${key}[[:space:]].*|${key} ${value}|" "$CONFIG"
  else
    echo "${key} ${value}" | sudo tee -a "$CONFIG" > /dev/null
  fi
}

# Deliberate pre-hardening baseline: both weak/open, both need fixing.
set_directive PasswordAuthentication yes
set_directive X11Forwarding yes

sudo sshd -t
sudo systemctl reload sshd 2>/dev/null || sudo systemctl reload ssh

# Safety net: leave the astrona admin user's own key-based access alone,
# just make sure its permissions are sane so it keeps working throughout.
if [[ -d "${HOME}/.ssh" ]]; then
  chmod 700 "${HOME}/.ssh"
  [[ -f "${HOME}/.ssh/authorized_keys" ]] && chmod 600 "${HOME}/.ssh/authorized_keys"
fi
