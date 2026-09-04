#!/usr/bin/env bash
# OS prep for PLAYGROUND — Link Aggregation with Linux Bonding (playground)
# Runs once when the environment comes up, as a regular user with passwordless
# sudo (the LFCS base image, like the graded labs). Environment preparation
# ONLY: iproute2, ethtool, kmod, and ifenslave all ship in the base image; this
# just makes the bonding module loadable. It deliberately does NOT create
# bond0 or assign any IP — building and inspecting the bond is the whole point
# of the playground.
set -euo pipefail

echo "[playground] linux-bonding-playground: preparing clean host..."

# Make the bonding driver available. Loading it with no parameters does not
# create any bond interface — `cat /proc/net/bonding/bond0` will simply fail
# until you create bond0 yourself.
sudo modprobe bonding || true
echo "bonding" | sudo tee /etc/modules-load.d/bonding.conf >/dev/null 2>&1 || true

echo
echo "[playground] network interfaces on this host:"
ip -brief link show || true

echo
echo "[playground] ready. The two extra NICs (segments 192.168.50.0/24 and"
echo "[playground] 192.168.51.0/24) are up at layer 2 with no IP and no bond."
echo "[playground] Do NOT reconfigure the interface carrying your SSH session."
echo "[playground] See docs/overview.md for things to try."
