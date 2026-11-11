#!/usr/bin/env bash
set -euo pipefail
sudo networkctl renew dhcp0
sleep 10
