#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Bootstrap: openssh-server, openssh-client, and sshpass (for validation's
# real password-based SSH login checks) all ship in the base LFCS image;
# this just makes sure the service is enabled and running.

set -eu

sudo systemctl enable --now sshd 2>/dev/null || sudo systemctl enable --now ssh
ASTRONA_STUDENT_SCRIPT
