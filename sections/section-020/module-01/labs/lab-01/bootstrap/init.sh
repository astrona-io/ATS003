#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Prepare safe disposable interfaces for the bond exercise.
set -eu

# Keep the prepared Netplan files across reboots. Cloud-init must not try
# to rename disposable interfaces using their previous boot's MAC addresses.
printf 'network: {config: disabled}\n' | sudo tee /etc/cloud/cloud.cfg.d/99-lab-network.cfg >/dev/null

# Remove inherited practice topology while preserving management networking.
sudo python3 - <<'NETPLAN_RESET'
from pathlib import Path
import yaml
for path in Path('/etc/netplan').glob('*.yaml'):
    data = yaml.safe_load(path.read_text()) or {}
    network = data.get('network', {})
    for group, names in [('bridges', ['br0']), ('bonds', ['bond0']),
                         ('ethernets', ['dummy0', 'dummy1', 'dummy2'])]:
        for name in names:
            network.get(group, {}).pop(name, None)
    path.write_text(yaml.safe_dump(data, sort_keys=False))
    path.chmod(0o600)
NETPLAN_RESET
sudo netplan apply
for interface in br0 bond0; do
  if ip link show "$interface" >/dev/null 2>&1; then
    sudo ip link delete "$interface"
  fi
done


# Identify the primary/default-route interface so we can explicitly refuse
# to ever create a dummy interface that collides with it by name.
PRIMARY_IFACE="$(ip -o -4 route show to default | awk '{print $5}' | head -n1)"
echo "Detected primary interface: ${PRIMARY_IFACE:-none}"

for IFACE in dummy1 dummy2; do
  if [[ -n "$PRIMARY_IFACE" && "$IFACE" == "$PRIMARY_IFACE" ]]; then
    echo "Refusing to create $IFACE: name collides with primary interface $PRIMARY_IFACE" >&2
    exit 1
  fi

  if ! ip link show "$IFACE" &> /dev/null; then
    sudo ip link add "$IFACE" type dummy
  fi

  sudo ip link set "$IFACE" nomaster
  sudo tee "/etc/systemd/network/20-${IFACE}.netdev" >/dev/null <<NETDEV
[NetDev]
Name=$IFACE
Kind=dummy
NETDEV
  sudo ip link set "$IFACE" up
done

ip -br link show
ASTRONA_STUDENT_SCRIPT
