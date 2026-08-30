#!/usr/bin/env bash
# OS prep for PLAYGROUND — Network Interfaces and IPv4 & IPv6 Addressing
# Runs once when the environment comes up, as a regular user with passwordless
# sudo (the LFCS base image, like the graded labs). Environment preparation
# ONLY: make sure the inspection tools are present, then put two extra NICs into
# two different, visible states so `ip link show` and `ip addr show` have
# something real to report. There is no task and no grading.
set -eu

echo "[playground] network-interfaces-playground: preparing clean host..."

# iproute2 carries `ip`; iputils-ping and ethtool help poke at link state. On
# the base image these are usually already there, so only touch apt if one is
# missing. Failures are non-fatal for a sandbox.
need_pkg=0
command -v ip     >/dev/null 2>&1 || need_pkg=1
command -v ping   >/dev/null 2>&1 || need_pkg=1
command -v ethtool >/dev/null 2>&1 || need_pkg=1
if [ "$need_pkg" -eq 1 ] && command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update -y || true
  sudo apt-get install -y --no-install-recommends iproute2 iputils-ping ethtool || true
fi

# The two extra NICs are dummy devices created here — astrona's qemu backend
# only does point-to-point segments (2 VMs each), so this one-VM sandbox cannot
# attach an isolated segment. A `dummy` device shows up in `ip link` / `ip addr`
# and behaves like a normal NIC for link-state and addressing. The management
# interface that carries SSH is a separate real NIC and is never touched here.
NIC_A="netlab-a"
NIC_B="netlab-b"

sudo modprobe dummy 2>/dev/null || true
sudo ip link add "$NIC_A" type dummy 2>/dev/null || true
sudo ip link add "$NIC_B" type dummy 2>/dev/null || true

# NIC A — one IPv4 address and one IPv6 address, interface UP. This is the
# "interface with addresses" the module inspects. 2001:db8::/32 is the
# documentation prefix (RFC 3849), safe on a device with no peer.
sudo ip addr add 192.168.50.10/24 dev "$NIC_A" 2>/dev/null || true
sudo ip -6 addr add 2001:db8:50::10/64 dev "$NIC_A" 2>/dev/null || true
sudo ip link set "$NIC_A" up || true

# NIC B — interface UP but NO address. This is the "UP does not mean it has an IP
# or can reach anything" example from the module.
sudo ip link set "$NIC_B" up || true

echo
echo "[playground] interface summary:"
ip -brief addr show || true

echo
echo "[playground] ready."
echo "[playground]   ${NIC_A}  — one IPv4 (192.168.50.10/24) + one IPv6 (2001:db8:50::10/64), UP"
echo "[playground]   ${NIC_B}  — UP, no IP address"
echo "[playground]   lo       — loopback (127.0.0.1/8 and ::1/128)"
echo "[playground] Everything set here is runtime-only and disappears on reboot."
echo "[playground] Do NOT reconfigure the interface that carries your SSH session."
echo "[playground] See docs/overview.md for things to try."
