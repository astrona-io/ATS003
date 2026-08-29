#!/usr/bin/env bash
# Shared OS prep for PLAYGROUND — NTP Client Time Synchronization
# Runs on BOTH VMs before their per-VM script. Environment preparation ONLY:
# install chrony and a couple of inspection tools. No source is configured here
# — that is the per-VM script's job (server) or yours to do by hand (client).
set -euo pipefail

echo "[playground] common prep: installing chrony..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  # chrony    = chronyd (the daemon) + chronyc (the query/control tool).
  # iproute2  = `ip` for checking the segment.
  # Missing packages are non-fatal for a sandbox.
  apt-get install -y --no-install-recommends chrony iproute2 || true
fi

# chrony's service unit on Ubuntu is `chrony`; make sure it is enabled.
systemctl enable chrony 2>/dev/null || true

echo "[playground] common prep done."
