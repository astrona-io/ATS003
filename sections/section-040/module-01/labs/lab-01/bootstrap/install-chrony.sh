#!/usr/bin/env bash
# Bootstrap: chrony ships in the base LFCS image; this just makes sure the
# service is enabled and running with its default /etc/chrony/chrony.conf
# for the task to edit.

set -eu

sudo systemctl enable chrony
sudo systemctl restart chrony
