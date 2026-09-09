#!/usr/bin/env bash
# Bootstrap: turns this VM into the partner-subnet gateway for the
# static-routing lab. Enables IP forwarding persistently and creates a
# dummy0 interface addressed 10.10.30.1/24, standing in for the
# partner subnet 10.10.30.0/24 the scenario describes. The target VM's
# route ultimately reaches this address, giving a real, pingable
# end-to-end proof instead of just a config check.

set -eu

# Persistent IP forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-gateway-forward.conf > /dev/null
sudo sysctl --system > /dev/null

# Live: create dummy0 now
if ! ip link show dummy0 &>/dev/null; then
  sudo ip link add dummy0 type dummy
fi
sudo ip addr replace 10.10.30.1/24 dev dummy0
sudo ip link set dummy0 up

# Persist dummy0 across reboot via an independent oneshot systemd unit,
# deliberately outside Netplan/NetworkManager/systemd-networkd so it can
# never conflict with whichever of those stacks manages the primary
# interface.
sudo tee /usr/local/sbin/create-gateway-dummy.sh > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
set -eu
ip link show dummy0 &>/dev/null || ip link add dummy0 type dummy
ip addr replace 10.10.30.1/24 dev dummy0
ip link set dummy0 up
SCRIPT
sudo chmod +x /usr/local/sbin/create-gateway-dummy.sh

sudo tee /etc/systemd/system/gateway-dummy.service > /dev/null <<'EOF'
[Unit]
Description=Create local dummy0 interface fronting the partner subnet for the static-routing lab
After=network-pre.target
Before=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/create-gateway-dummy.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now gateway-dummy.service > /dev/null
