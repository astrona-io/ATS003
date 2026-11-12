#!/usr/bin/env bash
set -eu
printf 'nameserver 127.0.0.2\noptions timeout:1 attempts:1\n' | sudo tee /etc/resolv.conf >/dev/null
