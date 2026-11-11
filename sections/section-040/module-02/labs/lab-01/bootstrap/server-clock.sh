#!/usr/bin/env bash
# The isolated training clock is not an authoritative UTC time source.
set -eu
sudo tee /etc/chrony/chrony.conf >/dev/null <<'EOF'
local stratum 10
driftfile /var/lib/chrony/chrony.drift
EOF
sudo systemctl restart chrony
