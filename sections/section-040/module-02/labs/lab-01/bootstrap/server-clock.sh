#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# The isolated training clock is not an authoritative UTC time source.
set -eu
sudo tee /etc/chrony/chrony.conf >/dev/null <<'EOF'
local stratum 10
driftfile /var/lib/chrony/chrony.drift
EOF
sudo systemctl restart chrony
ASTRONA_STUDENT_SCRIPT
