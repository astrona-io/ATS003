#!/usr/bin/env bash
# OS prep for PLAYGROUND — Network Troubleshooting Workflow
# Runs once at startup, as a regular user with passwordless sudo (the LFCS
# base image). iproute2, nftables, curl, tcpdump and python3 ship in the base
# image. traceroute and mtr may not; they are installed best effort. The
# management interface is never touched: all work happens on the dummy
# interface lab0.
set -euo pipefail

echo "[playground] network-troubleshooting-playground: preparing..."

# --- the practice antenna and the portal service -------------------------------
sudo ip link add lab0 type dummy 2>/dev/null || true
sudo ip addr replace 10.66.0.10/24 dev lab0
sudo ip link set lab0 up

sudo install -d /opt/portal
echo "portal online" | sudo tee /opt/portal/index.html > /dev/null
sudo tee /etc/systemd/system/portal.service > /dev/null <<'UNIT'
[Unit]
Description=Playground web service "portal" on port 8443
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
sudo systemctl enable --now portal.service 2>/dev/null || true

# --- the name -----------------------------------------------------------------
grep -q 'portal.lab' /etc/hosts || echo "10.66.0.10 portal.lab" | sudo tee -a /etc/hosts > /dev/null

# --- helper commands that break one rung each ----------------------------------
sudo tee /usr/local/bin/break-link > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
ip link set lab0 down
echo "break-link: lab0 is now down"
SCRIPT
sudo tee /usr/local/bin/break-name > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
sed -i '/portal\.lab/d' /etc/hosts
echo "10.66.0.20 portal.lab" >> /etc/hosts
echo "break-name: portal.lab now points at 10.66.0.20"
SCRIPT
sudo tee /usr/local/bin/break-firewall > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
nft add table inet lab_shield 2>/dev/null || true
nft add chain inet lab_shield output '{ type filter hook output priority 0 ; policy accept ; }' 2>/dev/null || true
nft add rule inet lab_shield output tcp dport 8443 drop
echo "break-firewall: outgoing tcp port 8443 is now dropped"
SCRIPT
sudo tee /usr/local/bin/fix-all > /dev/null <<'SCRIPT'
#!/usr/bin/env bash
ip link set lab0 up
sed -i '/portal\.lab/d' /etc/hosts
echo "10.66.0.10 portal.lab" >> /etc/hosts
nft delete table inet lab_shield 2>/dev/null || true
systemctl start portal.service
echo "fix-all: link up, name restored, firewall rule removed"
SCRIPT
sudo chmod 755 /usr/local/bin/break-link /usr/local/bin/break-name /usr/local/bin/break-firewall /usr/local/bin/fix-all

# --- diagnostic tools that may be missing --------------------------------------
if ! command -v traceroute >/dev/null 2>&1 || ! command -v mtr >/dev/null 2>&1; then
  sudo apt-get install -y traceroute mtr-tiny >/dev/null 2>&1 || \
    echo "[playground] could not install traceroute/mtr (no internet?); ping and tracepath still work" >&2
fi

echo
echo "[playground] ready. Healthy ship: lab0 10.66.0.10/24, portal on :8443, name portal.lab."
echo "[playground] Break one rung: sudo break-link | sudo break-name | sudo break-firewall"
echo "[playground] Put everything back: sudo fix-all"
