#!/usr/bin/env bash
# Bootstrap init: confirms the network-management tooling the scenario
# expects (netplan.io, iproute2) is present. Both ship in the base LFCS
# image, so there is nothing to install here.
#
# This script intentionally does NOT touch live addressing, /etc/hosts,
# or any netplan/NetworkManager config for the primary interface — the
# VM's primary interface is DHCP-managed and used for the astrona/SSH
# management connection, and must stay reachable. Adding the secondary
# IPv4/IPv6 addressing and the /etc/hosts entries is the student's task.

set -eu

IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "Detected primary interface: ${IFACE}"
