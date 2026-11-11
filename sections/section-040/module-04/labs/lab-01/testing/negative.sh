#!/usr/bin/env bash
set -euo pipefail
sudo mv /etc/systemd/resolved.conf.d/10-lab.conf /tmp/resolved.saved
