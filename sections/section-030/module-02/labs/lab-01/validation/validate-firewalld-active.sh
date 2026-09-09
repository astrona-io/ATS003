#!/usr/bin/env bash
# Confirms firewalld is both enabled (boot-persistent) and currently running.

set -u

active="$(systemctl is-active firewalld 2>/dev/null)"
enabled="$(systemctl is-enabled firewalld 2>/dev/null)"

if [[ "$active" == "active" && "$enabled" == "enabled" ]]; then
  echo "PASS: firewalld-active (active='$active', enabled='$enabled')"
  exit 0
else
  echo "FAIL: firewalld-active - active='$active', enabled='$enabled', expected active='active' enabled='enabled'"
  exit 1
fi
