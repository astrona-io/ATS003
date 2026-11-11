#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# OS prep for PLAYGROUND — Link Aggregation with Linux Bonding (playground)
# Runs once when the environment comes up, as a regular user with passwordless
# sudo (the LFCS base image, like the graded labs). Environment preparation
# ONLY: iproute2, ethtool, kmod, and ifenslave all ship in the base image; this
# just makes the bonding module loadable. It deliberately does NOT create
# bond0 or assign any IP — building and inspecting the bond is the whole point
# of the playground.
set -euo pipefail

echo "[playground] linux-bonding-playground: preparing clean host..."

# Load the driver without creating the bond that the student must build.
echo "options bonding max_bonds=0" | sudo tee /etc/modprobe.d/playground-bonding.conf >/dev/null
sudo modprobe bonding max_bonds=0
echo "bonding" | sudo tee /etc/modules-load.d/bonding.conf >/dev/null 2>&1 || true

echo
echo "[playground] network interfaces on this host:"
ip -brief link show || true

echo
echo "[playground] ready. The two practice interfaces bondport0 and"
echo "[playground] bondport1 have no IP and no bond."
echo "[playground] Do NOT reconfigure the interface carrying your SSH session."
echo "[playground] See docs/overview.md for things to try."
ASTRONA_STUDENT_SCRIPT
