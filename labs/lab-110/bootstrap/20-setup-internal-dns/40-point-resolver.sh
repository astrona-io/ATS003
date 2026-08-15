#!/usr/bin/env bash
# Bootstrap: points the system's default resolver at the local bind9
# instance (127.0.0.1) so a plain `dig data-001.internal.example.com`
# (no @server) actually returns an answer for the scenario's internal
# name, giving the task a real "system resolver" to compare against
# the direct @192.168.10.80 query.

set -eu

sudo rm -f /etc/resolv.conf
sudo tee /etc/resolv.conf > /dev/null <<'EOF'
nameserver 127.0.0.1
search internal.example.com
EOF
