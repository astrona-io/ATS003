#!/usr/bin/env bash
# Shared OS prep for PLAYGROUND — NTP Client Time Synchronization
# Runs on BOTH VMs before their per-VM script, as a regular user with
# passwordless sudo (the LFCS base image, like the graded labs). Environment
# preparation ONLY: chrony and iproute2 both ship in the base image already;
# this just makes sure the chrony service is enabled. No source is configured
# here — that is the per-VM script's job (server) or yours to do by hand
# (client).
set -euo pipefail

echo "[playground] common prep: enabling chrony..."

# chrony's service unit on Ubuntu is `chrony`; make sure it is enabled.
sudo systemctl enable chrony 2>/dev/null || true

echo "[playground] common prep done."
