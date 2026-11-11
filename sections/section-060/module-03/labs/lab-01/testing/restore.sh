#!/usr/bin/env bash
set -euo pipefail
handle=$(sudo nft -a list chain inet filter input | awk '/tcp dport 8080.*drop/{print $NF}')
test -n "$handle"
sudo nft delete rule inet filter input handle "$handle"
sudo nft list ruleset | sudo tee /etc/nftables.conf >/dev/null
