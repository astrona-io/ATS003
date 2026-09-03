#!/usr/bin/env bash
# Bootstrap init: ensures nftables tooling is present and the live
# ruleset starts genuinely empty. Does NOT create any tables, chains,
# or rules -- building the filtering/NAT logic is the lab task itself.

set -eu

if ! command -v nft >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y nftables
fi

# Wipe any ruleset baked into the base image so "sudo nft list ruleset"
# is empty at Step 0 of the guided solution, matching a fresh host.
sudo nft flush ruleset || true
