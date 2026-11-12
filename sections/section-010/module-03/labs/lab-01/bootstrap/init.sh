#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Bootstrap init: creates /opt/course for this lab's tasks.

set -eu

sudo mkdir -p /opt/course
sudo chmod 755 /opt/course
sudo chown student:student /opt/course
ASTRONA_STUDENT_SCRIPT
