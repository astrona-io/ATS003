#!/usr/bin/env bash
# Bootstrap init: creates /opt/course for this lab's tasks.

set -eu

sudo mkdir -p /opt/course
sudo chmod 755 /opt/course
sudo chown astrona:astrona /opt/course
