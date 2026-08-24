#!/usr/bin/env bash
# Bootstrap (client VM): resolves the dns VM's real address on the
# shared lab network *before* overwriting /etc/resolv.conf, then
# points the system resolver at it. This gives the task a real
# "system resolver" -> real authoritative-server hop across an actual
# network, instead of a single VM answering both roles on loopback.

set -eu

DNS_HOST="astrona-ats-003-lab-040-dns"

DNS_IP=""
for _ in $(seq 1 30); do
  DNS_IP="$(getent hosts "$DNS_HOST" 2>/dev/null | awk '{print $1}' | head -n1)"
  [[ -n "$DNS_IP" ]] && break
  sleep 2
done

if [[ -z "$DNS_IP" ]]; then
  echo "Could not resolve $DNS_HOST after retrying — aborting" >&2
  exit 1
fi

sudo rm -f /etc/resolv.conf
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver ${DNS_IP}
search internal.example.com
EOF

echo "Client resolver pointed at ${DNS_HOST} (${DNS_IP})"
