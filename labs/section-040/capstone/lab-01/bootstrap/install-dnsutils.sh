#!/usr/bin/env bash
# Bootstrap: installs dnsutils (dig, host, nslookup) so the DNS querying
# tools this lab's task relies on are present on a fresh base image.

set -eu

export DEBIAN_FRONTEND=noninteractive

if ! command -v dig >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y dnsutils
fi
