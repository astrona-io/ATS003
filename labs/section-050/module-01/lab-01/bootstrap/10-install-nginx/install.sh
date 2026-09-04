#!/usr/bin/env bash
# Bootstrap init: nginx ships in the base LFCS image; this just makes sure
# the service is enabled and running.

set -eu

sudo systemctl enable nginx
sudo systemctl start nginx
