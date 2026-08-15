#!/usr/bin/env bash
# Bootstrap: creates a local "eth1" dummy interface addressed on the
# 10.10.20.0/24 backend subnet described in the scenario, so the static
# route to 10.10.30.0/24 via gateway 10.10.20.1 dev eth1 can actually be
# added and verified on a single VM, without requiring a real second
# network segment.
#
# The VM's real primary/management interface is detected dynamically and
# never touched here, so its default route (and SSH/orchestration
# connectivity) is never at risk. The dummy interface is named "eth1"
# on purpose, since we control its creation and it must match the
# interface name used throughout the scenario/solution.

set -eu

# Detect (but never modify) the real primary/management interface, purely
# so we never accidentally collide with or reconfigure it.
PRIMARY_IFACE="$(ip -o -4 route show to default | awk '{print $5}' | head -n1)"
echo "Primary management interface detected: ${PRIMARY_IFACE:-unknown} (left untouched)"

# Create eth1 live now, if it doesn't already exist.
if ! ip link show eth1 &>/dev/null; then
  sudo ip link add eth1 type dummy
fi
sudo ip addr replace 10.10.20.5/24 dev eth1
sudo ip link set eth1 up

# Persist eth1's existence + address across reboot via a small, independent
# oneshot systemd unit. This is deliberately NOT done through Netplan /
# NetworkManager / systemd-networkd config, so it can never conflict with
# whichever of those stacks manages the primary interface, and so it does
# not pre-empt the persistent *route* the student is asked to configure.
sudo tee /usr/local/sbin/create-eth1-dummy.sh > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -eu
ip link show eth1 &>/dev/null || ip link add eth1 type dummy
ip addr replace 10.10.20.5/24 dev eth1
ip link set eth1 up
SCRIPT
sudo chmod +x /usr/local/sbin/create-eth1-dummy.sh

sudo tee /etc/systemd/system/eth1-dummy.service > /dev/null <<'EOF'
[Unit]
Description=Create local eth1 dummy interface for the static-routing lab
After=network-pre.target
Before=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/create-eth1-dummy.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now eth1-dummy.service > /dev/null
