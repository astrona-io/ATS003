#!/usr/bin/env bash
# Bootstrap init: `nft` ships in the base LFCS image, so this just makes
# sure the live ruleset starts genuinely empty. Does NOT create any
# tables, chains, or rules -- building the filtering/NAT logic is the
# lab task itself.

set -eu

sudo nft flush ruleset || true
