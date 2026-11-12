#!/usr/bin/env bash
set -eu
sudo nft insert rule inet filter input tcp dport 5000 accept
