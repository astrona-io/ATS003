#!/usr/bin/env bash
set -euo pipefail
sudo mv /tmp/resolved.saved /etc/systemd/resolved.conf.d/10-lab.conf
