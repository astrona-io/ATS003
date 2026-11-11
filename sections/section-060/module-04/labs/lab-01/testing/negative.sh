#!/usr/bin/env bash
set -euo pipefail
sudo nft insert rule inet filter input tcp dport 8080 drop
