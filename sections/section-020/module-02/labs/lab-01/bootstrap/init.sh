#!/usr/bin/env bash
# Bootstrap init: creates dummy0, dummy1, and dummy2 kernel "dummy" interfaces
# so this lab's bridge/bond tasks have safe, disposable NICs to enslave.
#
# A single default QEMU VM only has one real NIC (the management interface
# this SSH/console session depends on) — bridging or bonding it would break
# connectivity to the VM. Dummy interfaces give bridge/bond commands
# something real to operate on without ever touching that NIC.

set -eu

# Identify the primary/default-route interface so we can explicitly refuse
# to ever create a dummy interface that collides with it by name.
PRIMARY_IFACE="$(ip -o -4 route show to default | awk '{print $5}' | head -n1)"
echo "Detected primary interface: ${PRIMARY_IFACE:-none}"

for IFACE in dummy0 dummy1 dummy2; do
  if [[ -n "$PRIMARY_IFACE" && "$IFACE" == "$PRIMARY_IFACE" ]]; then
    echo "Refusing to create $IFACE: name collides with primary interface $PRIMARY_IFACE" >&2
    exit 1
  fi

  if ! ip link show "$IFACE" &> /dev/null; then
    sudo ip link add "$IFACE" type dummy
  fi

  sudo ip link set "$IFACE" up
done

ip -br link show
