#!/usr/bin/env bash
# Confirms the primary interface (the one holding the default route) is
# bound to the public zone, per `firewall-cmd --get-active-zones`.

set -u

IFACE="$(ip -o -4 route show to default | awk '{print $5}' | head -n1)"

if [[ -z "$IFACE" ]]; then
  echo "FAIL: interface-zone - could not detect a default-route interface"
  exit 1
fi

actual="$(firewall-cmd --get-zone-of-interface="$IFACE" 2>/dev/null)"

if [[ "$actual" == "public" ]]; then
  echo "PASS: interface-zone ($IFACE is bound to '$actual')"
  exit 0
else
  echo "FAIL: interface-zone - $IFACE is bound to '$actual', expected 'public'"
  exit 1
fi
