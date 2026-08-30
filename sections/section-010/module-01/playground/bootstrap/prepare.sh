#!/usr/bin/env bash
# OS prep for PLAYGROUND — Network Interfaces and IPv4 & IPv6 Addressing
# Runs once when the environment comes up. Environment preparation ONLY:
# install the tools the module inspects with, then put the two extra NICs into
# two different, visible states so `ip link show` and `ip addr show` have
# something real to report. There is no task and no grading.
set -euo pipefail

echo "[playground] network-interfaces-playground: preparing clean host..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  # iproute2 carries `ip`. iputils-ping and ethtool are handy for poking at
  # link state. Missing packages are non-fatal for a sandbox.
  apt-get install -y --no-install-recommends iproute2 iputils-ping ethtool || true
fi

# The two extra NICs are dummy devices created here — astrona's qemu backend
# only does point-to-point segments (2 VMs each), so this one-VM sandbox cannot
# attach an isolated segment. A `dummy` device shows up in `ip link` / `ip addr`
# and behaves like a normal NIC for link-state and addressing. The management
# interface that carries SSH is a separate real NIC and is never touched here.
NIC_A="netlab-a"
NIC_B="netlab-b"

modprobe dummy 2>/dev/null || true
ip link add "$NIC_A" type dummy 2>/dev/null || true
ip link add "$NIC_B" type dummy 2>/dev/null || true

# NIC A — one IPv4 address and one IPv6 address, interface UP. This is the
# "interface with addresses" the module inspects. 2001:db8::/32 is the
# documentation prefix (RFC 3849), safe on a device with no peer.
ip addr add 192.168.50.10/24 dev "$NIC_A" 2>/dev/null || true
ip -6 addr add 2001:db8:50::10/64 dev "$NIC_A" 2>/dev/null || true
ip link set "$NIC_A" up || true

# NIC B — interface UP but NO address. This is the "UP does not mean it has an IP
# or can reach anything" example from the module.
ip link set "$NIC_B" up || true

echo
echo "[playground] interface summary:"
ip -brief addr show || true

echo
echo "[playground] ready."
echo "[playground]   ${NIC_A:-<nic-a>}  — one IPv4 (192.168.50.10/24) + one IPv6 (2001:db8:50::10/64), UP"
echo "[playground]   ${NIC_B:-<nic-b>}  — UP, no IP address"
echo "[playground]   lo       — loopback (127.0.0.1/8 and ::1/128)"
echo "[playground] Everything set here is runtime-only and disappears on reboot."
echo "[playground] Do NOT reconfigure the interface that carries your SSH session."
echo "[playground] See docs/overview.md for things to try."
