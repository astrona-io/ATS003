#!/usr/bin/env bash
# OS prep for PLAYGROUND — Local Hostname Resolution
# Runs once when the environment comes up. Environment preparation ONLY: set the
# static hostname the module's examples use, make sure the lookup tools are
# present, and seed a couple of /etc/hosts entries to inspect. There is no task
# and no grading.
set -euo pipefail

echo "[playground] hostname-resolution-playground: preparing clean host..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  # `getent` ships in libc-bin (already present). Add ping for the reachability
  # comparison the module makes. A missing package is non-fatal for a sandbox.
  apt-get install -y --no-install-recommends iputils-ping || true
fi

NEWHOST="prod-app-01"

# Set the static hostname the module's examples use. hostnamectl needs a running
# systemd; fall back to the classic path when it is not there.
if [ -d /run/systemd/system ] && command -v hostnamectl >/dev/null 2>&1; then
  hostnamectl set-hostname "$NEWHOST" || true
else
  echo "$NEWHOST" > /etc/hostname || true
  hostname "$NEWHOST" 2>/dev/null || true
fi

# Make sure the standard localhost entries exist, then add a Debian-style
# 127.0.1.1 mapping for this host plus one example name pointing at a
# non-loopback address. Each line is added only if missing, so re-running
# prepare.sh is safe.
ensure_line() {
  grep -qxF "$1" /etc/hosts || printf '%s\n' "$1" >> /etc/hosts
}
ensure_line "127.0.0.1 localhost"
ensure_line "::1 localhost ip6-localhost ip6-loopback"
ensure_line "127.0.1.1 $NEWHOST app-server"
ensure_line "192.168.50.10 db-primary db"

echo
echo "[playground] /etc/hosts now:"
cat /etc/hosts
echo
echo "[playground] nsswitch hosts line:"
grep '^hosts:' /etc/nsswitch.conf || true

echo
echo "[playground] ready. static hostname = $NEWHOST"
echo "[playground]   getent hosts $NEWHOST   -> 127.0.1.1  (loopback, this machine only)"
echo "[playground]   getent hosts db-primary -> 192.168.50.10  (interface-style address; nothing is listening there)"
echo "[playground] /etc/hosts edits take effect immediately and survive a reboot;"
echo "[playground] the whole VM is discarded on 'astrona destroy'."
echo "[playground] See docs/overview.md for things to try."
