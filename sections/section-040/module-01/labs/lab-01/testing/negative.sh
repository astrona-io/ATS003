#!/usr/bin/env bash
set -euo pipefail
sudo sed -i '/^pool 0.pool.ntp.org /d' /etc/chrony/chrony.conf
