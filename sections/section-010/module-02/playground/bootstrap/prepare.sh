#!/usr/bin/env bash
# OS prep for PLAYGROUND — Managing Linux Hostnames
# Runs once when the environment comes up. Environment preparation ONLY: put the
# three hostname types into three visibly different states so `hostnamectl
# status` has something to show and the reader has something to change. There is
# no task and no grading.
set -euo pipefail

echo "[playground] linux-hostnames-playground: preparing clean host..."

# hostnamectl and hostname ship with the base system — nothing to install.

if [ -d /run/systemd/system ] && command -v hostnamectl >/dev/null 2>&1; then
  # Plain static hostname, and NO pretty hostname, so both are clearly the
  # reader's to set while working through the module.
  hostnamectl set-hostname "web-01" --static || true
  hostnamectl set-hostname "" --pretty || true
  # Seed a transient (kernel) hostname that differs from the static one. On a
  # real host this value would come from DHCP or boot-time config; setting it
  # here is the only way to make the static-vs-transient distinction visible in
  # a sandbox with no DHCP server. `hostnamectl status` then prints a separate
  # "Transient hostname:" line.
  hostnamectl set-hostname "dhcp-guest-42" --transient || true
else
  # Fallback if systemd is not the init system in this image.
  echo "web-01" > /etc/hostname || true
  hostname "dhcp-guest-42" 2>/dev/null || true
fi

echo
echo "[playground] hostnamectl status:"
hostnamectl status || true

echo
echo "[playground] ready."
echo "[playground]   static    = web-01         (persistent; stored in /etc/hostname)"
echo "[playground]   transient = dhcp-guest-42  (kernel runtime value; a static hostname normally overrides it)"
echo "[playground]   pretty    = <unset>"
echo "[playground] Change them with:  sudo hostnamectl set-hostname <name> [--static|--pretty|--transient]"
echo "[playground] Static and pretty changes persist across a reboot; the transient value does not."
echo "[playground] See docs/overview.md for things to try."
