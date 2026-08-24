#!/usr/bin/env bash
# Bootstrap: installs traceroute so the solution's verification commands
# (traceroute 10.10.30.5) run without a "command not found" error.

set -eu

if ! command -v traceroute >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y traceroute
fi
