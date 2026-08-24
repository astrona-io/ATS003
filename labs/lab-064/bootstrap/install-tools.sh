#!/usr/bin/env bash
# Bootstrap: ensures the diagnostic tools this lab drills (ss, tcpdump, nft)
# are present. tcpdump in particular is often not preinstalled on a base
# cloud image, unlike ss (part of iproute2, almost always already present).

set -eu

need_update=0
command -v tcpdump >/dev/null 2>&1 || need_update=1
command -v ss >/dev/null 2>&1 || need_update=1
command -v nft >/dev/null 2>&1 || need_update=1

if [[ "$need_update" -eq 1 ]]; then
  sudo apt-get update -y
fi

command -v tcpdump >/dev/null 2>&1 || sudo apt-get install -y tcpdump
command -v ss >/dev/null 2>&1 || sudo apt-get install -y iproute2
command -v nft >/dev/null 2>&1 || sudo apt-get install -y nftables
command -v curl >/dev/null 2>&1 || sudo apt-get install -y curl
