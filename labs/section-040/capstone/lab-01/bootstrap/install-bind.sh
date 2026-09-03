#!/usr/bin/env bash
# Bootstrap: installs bind9 to act as this lab's internal authoritative
# DNS server for the fictional internal.example.com zone the scenario
# refers to. There is no separate downstream DNS host in this
# single-VM lab, so this VM plays both roles: the querying client
# (`terminal`) and the internal authoritative server it queries directly.

set -eu

export DEBIAN_FRONTEND=noninteractive

if ! command -v named >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y bind9 bind9utils
fi
