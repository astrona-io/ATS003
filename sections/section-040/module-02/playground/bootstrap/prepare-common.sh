#!/usr/bin/env bash
# Shared OS prep for PLAYGROUND — NTP Server Mode and Stratums
# Runs on BOTH VMs before their per-VM script, as a regular user with
# passwordless sudo (the LFCS base image, like the graded labs). Environment
# preparation ONLY: chrony and iproute2 both ship in the base image already;
# this just makes sure the chrony service is enabled.
set -euo pipefail

echo "[playground] common prep: enabling chrony..."

sudo systemctl enable chrony 2>/dev/null || true

echo "[playground] common prep done."
