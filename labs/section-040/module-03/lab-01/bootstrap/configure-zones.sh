#!/usr/bin/env bash
# Bootstrap (dns VM): writes the forward (internal.example.com) and
# reverse (10.168.192.in-addr.arpa) zone files bind9 serves
# authoritatively, matching the records the scenario and its guided
# solution reference: data-001.internal.example.com -> 192.168.10.80
# (a fictional in-zone target address, not this VM's own address), an
# NS record for ns1.internal.example.com, an MX record for
# mail.internal.example.com, and a PTR record back to data-001.

set -eu

sudo mkdir -p /etc/bind/zones

sudo tee /etc/bind/zones/db.internal.example.com > /dev/null <<'EOF'
$TTL 300
@       IN      SOA     ns1.internal.example.com. admin.internal.example.com. (
                        2024010101 ; serial
                        3600       ; refresh
                        900        ; retry
                        604800     ; expire
                        300 )      ; negative cache TTL

@               IN      NS      ns1.internal.example.com.
@               IN      MX      10 mail.internal.example.com.

ns1             IN      A       192.168.10.80
mail            IN      A       192.168.10.80
data-001        IN      A       192.168.10.80
EOF

sudo tee /etc/bind/zones/db.192.168.10 > /dev/null <<'EOF'
$TTL 300
@       IN      SOA     ns1.internal.example.com. admin.internal.example.com. (
                        2024010101 ; serial
                        3600       ; refresh
                        900        ; retry
                        604800     ; expire
                        300 )      ; negative cache TTL

@       IN      NS      ns1.internal.example.com.

80      IN      PTR     data-001.internal.example.com.
EOF

sudo tee /etc/bind/named.conf.local > /dev/null <<'EOF'
zone "internal.example.com" {
    type master;
    file "/etc/bind/zones/db.internal.example.com";
};

zone "10.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.192.168.10";
};
EOF

sudo tee /etc/bind/named.conf.options > /dev/null <<'EOF'
options {
    directory "/var/cache/bind";

    listen-on { any; };
    listen-on-v6 { none; };
    allow-query { any; };

    recursion no;
    dnssec-validation no;
};
EOF

sudo named-checkconf
sudo named-checkzone internal.example.com /etc/bind/zones/db.internal.example.com
sudo named-checkzone 10.168.192.in-addr.arpa /etc/bind/zones/db.192.168.10

if systemctl list-unit-files | grep -q '^named\.service'; then
  bind_service="named"
else
  bind_service="bind9"
fi

sudo systemctl enable "$bind_service"
sudo systemctl restart "$bind_service"
