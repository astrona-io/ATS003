#!/usr/bin/env bash
# OS prep for PLAYGROUND — Software Bridging (playground)
# Runs once when the environment comes up. Environment preparation ONLY:
# install the tools the module explores with. It deliberately does NOT create
# br0, does NOT enslave any interface, and does NOT assign an IP — building and
# inspecting the bridge is the whole point of the playground.
set -euo pipefail

echo "[playground] linux-bridging-playground: preparing clean host..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  # iproute2 carries `ip` and `bridge`. bridge-utils adds the legacy `brctl`.
  # ethtool is handy for per-port link detail. Missing packages are non-fatal
  # for a sandbox.
  apt-get install -y --no-install-recommends iproute2 bridge-utils ethtool || true
fi

# The bridge driver is built in or auto-loaded when the first bridge is
# created, so nothing to modprobe here.

# Keep the two extra NICs DOWN so a reader who bridges them both without
# enabling STP does not open a Layer 2 loop before they mean to.
for dev in $(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$'); do
  # leave the interface that carries the SSH session alone
  if ip -o -4 addr show dev "$dev" 2>/dev/null | grep -q 'inet '; then
    continue
  fi
  ip link set "$dev" down 2>/dev/null || true
done

echo
echo "[playground] network interfaces on this host:"
ip -brief link show || true

echo
echo "[playground] ready. Two extra NICs face the same 192.168.60.0/24 segment,"
echo "[playground] both DOWN, no IP, no bridge. Bridging both of them together is"
echo "[playground] a deliberate Layer 2 loop — enable STP (stp_state 1) before you"
echo "[playground] bring the second port up. Do NOT reconfigure the SSH interface."
echo "[playground] See docs/overview.md for things to try."
