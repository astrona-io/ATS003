#!/usr/bin/env bash
# Bootstrap init: makes sure the network-management tooling the scenario
# expects (Netplan and, as a fallback, NetworkManager) is present. On the
# stock Ubuntu 24.04 cloud image this is normally already installed, so
# these installs are expected to be no-ops most of the time.
#
# This script intentionally does NOT touch live addressing, /etc/hosts,
# or any netplan/NetworkManager config for the primary interface — the
# VM's primary interface is DHCP-managed and used for the astrona/SSH
# management connection, and must stay reachable. Adding the secondary
# IPv4/IPv6 addressing and the /etc/hosts entries is the student's task.

set -eu

IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "Detected primary interface: ${IFACE}"

export DEBIAN_FRONTEND=noninteractive

if ! dpkg -s netplan.io >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends netplan.io
fi

if ! command -v ip >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends iproute2
fi
