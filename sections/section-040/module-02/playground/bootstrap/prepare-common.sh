#!/usr/bin/env bash
# Shared OS prep for PLAYGROUND — NTP Server Mode and Stratums
# Runs on BOTH VMs before their per-VM script. Environment preparation ONLY:
# install chrony and inspection tools.
set -euo pipefail

echo "[playground] common prep: installing chrony..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  # chrony   = chronyd (daemon) + chronyc (query/control tool).
  # iproute2 = `ip` for checking the segment.
  # Missing packages are non-fatal for a sandbox.
  apt-get install -y --no-install-recommends chrony iproute2 || true
fi

systemctl enable chrony 2>/dev/null || true

echo "[playground] common prep done."
