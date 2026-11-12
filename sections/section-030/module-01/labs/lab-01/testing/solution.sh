#!/usr/bin/env bash
set -eu
sudo nft -f - <<'EOF'
flush ruleset
table inet filter {
 chain input {
  type filter hook input priority 0; policy accept;
  tcp dport 5000 drop
  ip saddr 192.168.10.80 tcp dport 6002 accept
  tcp dport 6002 drop
 }
 chain output {
  type filter hook output priority 0; policy accept;
  ip daddr 192.168.10.70 drop
 }
}
table ip nat {
 chain prerouting {
  type nat hook prerouting priority dstnat; policy accept;
  tcp dport 6000 redirect to :6001
 }
}
EOF
