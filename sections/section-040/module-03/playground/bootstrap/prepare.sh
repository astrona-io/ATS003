#!/usr/bin/env bash
# OS prep for PLAYGROUND — DNS Verification with dig
# Runs once at startup, as a regular user with passwordless sudo (the LFCS
# base image, like the graded labs). Environment preparation ONLY: bind9,
# bind9-dnsutils (dig/nslookup/host), and bind9utils (named-checkconf/
# named-checkzone) all ship in the base image already. This loads a made-up
# zone `lab.example` (+ its reverse zone) so every dig query type resolves
# offline, and points the machine's own resolver at 127.0.0.1. There is
# nothing to solve — the zone is deliberately fully populated so you can
# query it, not build it.
set -euo pipefail

echo "[playground] dns-dig-playground: configuring local BIND server..."

# --- the zone data --------------------------------------------------------------
# Documentation IP ranges only: 203.0.113.0/24 (TEST-NET-3), 2001:db8::/32.

sudo tee /etc/bind/db.lab.example > /dev/null <<'EOF'
$TTL 3600
@       IN  SOA ns1.lab.example. admin.lab.example. (
                2024010101 ; serial
                3600       ; refresh
                900        ; retry
                604800     ; expire
                300 )      ; negative-cache TTL
@       IN  NS   ns1.lab.example.
@       IN  MX   10 mail.lab.example.
@       IN  A    203.0.113.10
@       IN  TXT  "v=spf1 ip4:203.0.113.20 -all"
ns1     IN  A    203.0.113.2
www     IN  A    203.0.113.10
www     IN  AAAA 2001:db8:113::10
mail    IN  A    203.0.113.20
app1    IN  A    203.0.113.31
app2    IN  A    203.0.113.32
web     IN  CNAME www.lab.example.
_dmarc  IN  TXT  "v=DMARC1; p=none"
; low TTL so `dig` shows the value counting down on repeat queries
short   30  IN  A    203.0.113.99
EOF

sudo tee /etc/bind/db.203.0.113 > /dev/null <<'EOF'
$TTL 3600
@       IN  SOA ns1.lab.example. admin.lab.example. (
                2024010101 3600 900 604800 300 )
@       IN  NS   ns1.lab.example.
10      IN  PTR  www.lab.example.
20      IN  PTR  mail.lab.example.
31      IN  PTR  app1.lab.example.
32      IN  PTR  app2.lab.example.
EOF

sudo tee /etc/bind/named.conf.local > /dev/null <<'EOF'
// Forward zone — transfer allowed from localhost so `dig AXFR` works from here.
zone "lab.example" {
    type master;
    file "/etc/bind/db.lab.example";
    allow-transfer { localhost; };
};

// Reverse zone — transfer left at the safe default (deny), so `dig AXFR`
// against it is refused.
zone "113.0.203.in-addr.arpa" {
    type master;
    file "/etc/bind/db.203.0.113";
};
EOF

# Authoritative only — no recursion, no upstream. IPv4 listen on all addresses.
sudo tee /etc/bind/named.conf.options > /dev/null <<'EOF'
options {
    directory "/var/cache/bind";
    recursion no;
    allow-transfer { none; };
    dnssec-validation no;
    listen-on { any; };
    listen-on-v6 { none; };
};
EOF

sudo named-checkconf && echo "[playground] named.conf OK" || echo "[playground] named.conf WARNING" >&2
sudo named-checkzone lab.example /etc/bind/db.lab.example || true
sudo named-checkzone 113.0.203.in-addr.arpa /etc/bind/db.203.0.113 || true

sudo systemctl enable named 2>/dev/null || true
sudo systemctl restart named 2>/dev/null || sudo systemctl restart bind9 2>/dev/null || true

# --- point this machine's own resolver at the local server --------------------
# Best effort: the plain `dig lab.example` form (no @server) then works too.
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
  sudo systemctl disable --now systemd-resolved 2>/dev/null || true
fi
sudo rm -f /etc/resolv.conf
sudo tee /etc/resolv.conf > /dev/null <<'EOF'
nameserver 127.0.0.1
search lab.example
options edns0
EOF

echo
echo "[playground] check: dig @127.0.0.1 lab.example SOA +short"
dig @127.0.0.1 lab.example SOA +short 2>/dev/null || true

echo
echo "[playground] ready. A local BIND server answers for lab.example (and its"
echo "[playground] reverse zone) on 127.0.0.1. Try: dig lab.example ANY,"
echo "[playground] dig www.lab.example, dig -x 203.0.113.10, dig lab.example AXFR."
echo "[playground] There is no internet DNS here — query 127.0.0.1. See docs/overview.md."
