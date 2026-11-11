#!/usr/bin/env bash
set -euo pipefail
sudo firewall-cmd --zone=public --remove-service=https
