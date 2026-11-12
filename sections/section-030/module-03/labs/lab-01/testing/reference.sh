#!/usr/bin/env bash
set -euo pipefail
inside=$(ip -o -4 addr show | awk '$4 == "172.20.10.1/24" {print $2}')
outside=$(ip -o -4 addr show | awk '$4 == "172.20.20.1/24" {print $2}')
test -n "$inside"; test -n "$outside"
printf 'net.ipv4.ip_forward=1\n' | sudo tee /etc/sysctl.d/90-lfcs-router.conf >/dev/null
sudo sysctl -p /etc/sysctl.d/90-lfcs-router.conf
sudo tee /etc/nftables.conf >/dev/null <<EOF
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    iifname "$inside" oifname "$outside" ip saddr 172.20.10.0/24 ip daddr 172.20.20.20 tcp dport 8080 accept
  }
}
table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat; policy accept;
    oifname "$outside" ip saddr 172.20.10.0/24 masquerade
  }
}
EOF
sudo nft -c -f /etc/nftables.conf
sudo nft -f /etc/nftables.conf
sudo systemctl enable nftables
