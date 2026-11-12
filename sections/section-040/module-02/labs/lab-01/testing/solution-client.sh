#!/usr/bin/env bash
set -eu
sudo tee /etc/chrony/chrony.conf >/dev/null <<'EOF'
server 192.168.10.123 iburst minpoll 2 maxpoll 4
makestep 1.0 3
driftfile /var/lib/chrony/chrony.drift
EOF
sudo systemctl restart chrony
for attempt in $(seq 1 60); do
  if chronyc -n sources | grep -Eq '^\^\*[[:space:]]+192\.168\.10\.123[[:space:]]'; then exit 0; fi
  sleep 2
done
echo 'Client did not synchronize to lab server' >&2
exit 1
