#!/usr/bin/env bash
# Bootstrap: installs curl (HTTP-based public-IP lookup) and dnsutils
# (provides dig, for the DNS-based public-IP lookup) so both methods
# in the Scenario are actually available on the VM.

set -eu

export DEBIAN_FRONTEND=noninteractive

if ! command -v curl >/dev/null 2>&1 || ! command -v dig >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y curl dnsutils
fi
