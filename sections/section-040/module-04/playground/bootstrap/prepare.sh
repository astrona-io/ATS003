#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# OS prep for PLAYGROUND — DNS Client Resolution
# Runs once at startup, as a regular user with passwordless sudo (the LFCS
# base image). bind9, bind9utils, dnsutils and systemd-resolved ship in the
# base image. A BIND server answers for lab.example on the dummy interface
# dns0 (10.55.0.53). The resolver is deliberately NOT pointed at it.
set -euo pipefail

missing=()
for package in bind9 dnsutils; do
  dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q 'install ok installed' || missing+=("$package")
done
if [ "${#missing[@]}" -gt 0 ]; then
  sudo apt-get update -y
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
fi

echo "[playground] dns-resolver-playground: preparing..."

# --- the practice antenna ------------------------------------------------------
sudo ip link add dns0 type dummy 2>/dev/null || true
sudo ip addr replace 10.55.0.53/24 dev dns0
sudo ip link set dns0 up

# --- the zone (documentation address range 203.0.113.0/24 only) ----------------
sudo tee /etc/bind/db.lab.example > /dev/null <<'ZONE'
$TTL 300
@       IN  SOA ns1.lab.example. admin.lab.example. (
                2024010101 ; serial
                3600       ; refresh
                900        ; retry
                604800     ; expire
                300 )      ; negative-cache TTL
@       IN  NS   ns1.lab.example.
ns1     IN  A    10.55.0.53
www     IN  A    203.0.113.10
db      IN  A    203.0.113.20
app     IN  A    203.0.113.30
ZONE

sudo tee /etc/bind/named.conf.local > /dev/null <<'ZONECONF'
zone "lab.example" {
    type master;
    file "/etc/bind/db.lab.example";
};
ZONECONF

sudo tee /etc/bind/named.conf.options > /dev/null <<'OPTIONS'
options {
    directory "/var/cache/bind";
    recursion no;
    dnssec-validation no;
    listen-on { 10.55.0.53; };
    listen-on-v6 { none; };
};
OPTIONS

sudo named-checkconf
sudo named-checkzone lab.example /etc/bind/db.lab.example >/dev/null
sudo systemctl enable named 2>/dev/null || true
sudo systemctl restart named 2>/dev/null || sudo systemctl restart bind9

# --- systemd-resolved stays at the Ubuntu defaults --------------------------------
sudo systemctl enable --now systemd-resolved 2>/dev/null || true
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo rm -f /etc/systemd/resolved.conf.d/10-lab.conf

echo
echo "[playground] check: dig +short @10.55.0.53 www.lab.example"
dig +short @10.55.0.53 www.lab.example 2>/dev/null || true
echo
echo "[playground] ready. BIND answers for lab.example on 10.55.0.53."
echo "[playground] systemd-resolved is at its defaults and does not know that server yet."
ASTRONA_STUDENT_SCRIPT
