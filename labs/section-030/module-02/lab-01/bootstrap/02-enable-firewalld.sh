#!/usr/bin/env bash
# Bootstrap: enables and starts firewalld, and makes sure the primary
# interface has a sane, correct zone binding before the student's task
# begins.
#
# Never hardcode an interface name (eth0 may not exist under this image's
# network stack) - detect whichever interface actually holds the default
# route instead.

set -eu

sudo systemctl enable --now firewalld

# Give firewalld's D-Bus interface a moment to come up before firewall-cmd
# starts talking to it.
for _ in $(seq 1 30); do
  if sudo firewall-cmd --state >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

IFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)

if [ -z "$IFACE" ]; then
  echo "bootstrap: could not detect a default-route interface" >&2
  exit 1
fi

sudo firewall-cmd --set-default-zone=public

# Bind the interface to public both at runtime and permanently, so
# --get-active-zones reflects it immediately and it still holds after
# the --reload the student's task will trigger.
sudo firewall-cmd --zone=public --change-interface="$IFACE"
sudo firewall-cmd --zone=public --change-interface="$IFACE" --permanent

sudo firewall-cmd --reload
