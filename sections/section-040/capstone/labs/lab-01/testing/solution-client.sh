#!/usr/bin/env bash
set -eu
getent hosts "$(hostname)" >/dev/null || printf "127.0.1.1 %s\n" "$(hostname)" | sudo tee -a /etc/hosts >/dev/null
sudo rm -f /etc/resolv.conf
printf 'nameserver 192.168.10.53\nsearch internal.example.com\n' | sudo tee /etc/resolv.conf >/dev/null
