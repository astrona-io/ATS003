#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
set -euo pipefail
sudo -n bash <<'ROOT'
set -euo pipefail
systemctl disable --now firewalld 2>/dev/null || true
nft flush ruleset
ip netns add nft-client
ip link add nft-host type veth peer name nft-peer
ip link set nft-peer netns nft-client
ip address add 192.168.10.1/24 dev nft-host
ip link set nft-host up
ip netns exec nft-client ip link set lo up
ip netns exec nft-client ip address add 192.168.10.80/24 dev nft-peer
ip netns exec nft-client ip address add 192.168.10.81/24 dev nft-peer
ip netns exec nft-client ip address add 192.168.10.70/24 dev nft-peer
ip netns exec nft-client ip link set nft-peer up
for port in 5000 6001 6002; do
  mkdir -p "/srv/nft-test/$port"
  printf 'listener-%s\n' "$port" >"/srv/nft-test/$port/index.html"
  cat >"/etc/systemd/system/lab-port-$port.service" <<EOF
[Unit]
Description=Firewall test listener $port
[Service]
ExecStart=/usr/bin/python3 -m http.server $port --directory /srv/nft-test/$port
User=nobody
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
done
mkdir -p /srv/nft-test/egress
printf 'egress-listener\n' >/srv/nft-test/egress/index.html
cat >/etc/systemd/system/lab-egress-peer.service <<'EOF'
[Unit]
Description=Private firewall egress peer
[Service]
ExecStart=/usr/sbin/ip netns exec nft-client /usr/bin/python3 -m http.server 9000 --directory /srv/nft-test/egress
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now lab-port-5000 lab-port-6001 lab-port-6002 lab-egress-peer
ROOT
ASTRONA_STUDENT_SCRIPT
