#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Bootstrap init: sets a generic pre-rename static hostname, as if this
# host was freshly provisioned from a base image and never customized.

set -eu

sudo hostnamectl set-hostname ubuntu-2404-base
ASTRONA_STUDENT_SCRIPT
