#!/usr/bin/env bash
set -eu
sudo sysctl -w net.ipv4.ip_forward=0
