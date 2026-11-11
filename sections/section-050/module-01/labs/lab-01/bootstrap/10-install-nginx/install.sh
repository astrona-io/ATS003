#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Bootstrap init: nginx ships in the base LFCS image; this just makes sure
# the service is enabled and running.

set -eu

sudo systemctl enable nginx
sudo systemctl start nginx
ASTRONA_STUDENT_SCRIPT
