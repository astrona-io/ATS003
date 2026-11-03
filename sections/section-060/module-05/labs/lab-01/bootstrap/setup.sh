#!/usr/bin/env bash
# Bootstrap: creates lab0 and the portal service, then breaks three rungs of
# the troubleshooting ladder: link down, wrong name entry, firewall drop.
set -eu

sudo ip link add lab0 type dummy 2>/dev/null || true
sudo ip addr replace 10.66.0.10/24 dev lab0
sudo ip link set lab0 up

sudo install -d /opt/portal
echo "portal online" | sudo tee /opt/portal/index.html > /dev/null
sudo tee /etc/systemd/system/portal.service > /dev/null <<'UNIT'
[Unit]
Description=Lab web service "portal" on port 8443
After=network.target

[Service]
WorkingDirectory=/opt/portal
ExecStart=/usr/bin/python3 -m http.server 8443 --bind 0.0.0.0
Restart=on-failure
DynamicUser=yes

[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload
sudo systemctl enable --now portal.service

# Fault 2: the wrong address for the name.
sudo sed -i '/portal\.lab/d' /etc/hosts
echo "10.66.0.20 portal.lab" | sudo tee -a /etc/hosts > /dev/null

# Fault 3: the shields drop outgoing tcp port 8443.
sudo nft add table inet lab_shield
sudo nft add chain inet lab_shield output '{ type filter hook output priority 0 ; policy accept ; }'
sudo nft add rule inet lab_shield output tcp dport 8443 drop

# Fault 1: the antenna is switched off.
sudo ip link set lab0 down
