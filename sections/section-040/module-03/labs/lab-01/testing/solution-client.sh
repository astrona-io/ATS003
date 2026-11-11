#!/usr/bin/env bash
set -eu
sudo rm -f /etc/resolv.conf
printf 'nameserver 192.168.10.53\nsearch internal.example.com\n' | sudo tee /etc/resolv.conf >/dev/null
