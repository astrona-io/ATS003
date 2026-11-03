#!/usr/bin/env bash
# Builds the harbour for the DHCP lab: veth pair dhcpsrv0/dhcp0 and a networkd DHCP server on 10.77.0.1/24.
set -eu
export DEBIAN_FRONTEND=noninteractive

# Linked pair of virtual antennas: dhcpsrv0 (harbour master) and dhcp0 (client).
sudo tee /etc/systemd/network/05-dhcp-lab.netdev >/dev/null <<'NETDEV'
[NetDev]
Name=dhcpsrv0
Kind=veth

[Peer]
Name=dhcp0
NETDEV

# The server end gets a fixed address and a small DHCP pool.
sudo tee /etc/systemd/network/05-dhcpsrv0.network >/dev/null <<'NETWORK'
[Match]
Name=dhcpsrv0

[Network]
Address=10.77.0.1/24
DHCPServer=yes

[DHCPServer]
PoolOffset=100
PoolSize=50
DefaultLeaseTimeSec=600
MaxLeaseTimeSec=600
EmitRouter=yes
EmitDNS=yes
DNS=10.77.0.1
NETWORK

sudo systemctl enable --now systemd-networkd >/dev/null 2>&1 || true
sudo networkctl reload || true
sudo systemctl restart systemd-networkd
sudo networkctl up dhcpsrv0 >/dev/null 2>&1 || true
sudo ip link set dhcp0 up 2>/dev/null || true

echo "dhcp lab ready"
