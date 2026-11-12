#!/usr/bin/env bash
set -euo pipefail
sudo nmcli connection modify lab-static ipv4.addresses 192.168.120.99/24
