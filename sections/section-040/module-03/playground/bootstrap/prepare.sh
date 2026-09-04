#!/usr/bin/env bash
# OS prep for PLAYGROUND — DNS Verification with dig
# Runs once at startup. Environment preparation ONLY: install `dig` and a local
# authoritative BIND server, load a made-up zone `lab.example` (+ its reverse
# zone) so every dig query type resolves offline, and point the machine's own
# resolver at 127.0.0.1. There is nothing to solve — the zone is deliberately
# fully populated so you can query it, not build it.
set -euo pipefail

echo "[playground] dns-dig-playground: installing dig + BIND..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  # bind9            = the `named` authoritative server.
  # bind9-dnsutils   = `dig`, `nslookup`, `host`.
  # bind9-utils      = `named-checkconf`, `named-checkzone`.
  apt-get install -y --no-install-recommends bind9 bind9-dnsutils bind9utils || true
fi

# --- the zone data --------------------------------------------------------------
# Documentation IP ranges only: 203.0.113.0/24 (TEST-NET-3), 2001:db8::/32.

cat > /etc/bind/db.lab.example <<'EOF'
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

cat > /etc/bind/db.203.0.113 <<'EOF'
$TTL 3600
@       IN  SOA ns1.lab.example. admin.lab.example. (
                2024010101 3600 900 604800 300 )
@       IN  NS   ns1.lab.example.
10      IN  PTR  www.lab.example.
20      IN  PTR  mail.lab.example.
31      IN  PTR  app1.lab.example.
32      IN  PTR  app2.lab.example.
EOF

cat > /etc/bind/named.conf.local <<'EOF'
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
cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    recursion no;
    allow-transfer { none; };
    dnssec-validation no;
    listen-on { any; };
    listen-on-v6 { none; };
};
EOF

named-checkconf && echo "[playground] named.conf OK" || echo "[playground] named.conf WARNING" >&2
named-checkzone lab.example /etc/bind/db.lab.example || true
named-checkzone 113.0.203.in-addr.arpa /etc/bind/db.203.0.113 || true

systemctl enable named 2>/dev/null || true
systemctl restart named 2>/dev/null || systemctl restart bind9 2>/dev/null || true

# --- point this machine's own resolver at the local server --------------------
# Best effort: the plain `dig lab.example` form (no @server) then works too.
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
  systemctl disable --now systemd-resolved 2>/dev/null || true
fi
rm -f /etc/resolv.conf
cat > /etc/resolv.conf <<'EOF'
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
