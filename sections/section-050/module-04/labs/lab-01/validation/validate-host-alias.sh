#!/usr/bin/env bash
# Checks the Host station entry and a real batch-mode login as cadet.
set -u

settings="$(sudo -u cadet ssh -G station 2>/dev/null)"

for expected in "hostname localhost" "user pilot" "port 2222"; do
  if ! echo "$settings" | grep -qx "$expected"; then
    echo "FAIL: host-alias - 'ssh -G station' does not report '${expected}'"
    exit 1
  fi
done

if ! echo "$settings" | grep -q '^identityfile .*/\.ssh/id_ed25519$'; then
  echo "FAIL: host-alias - IdentityFile ~/.ssh/id_ed25519 is not set for station"
  exit 1
fi

if sudo -u cadet ssh -o BatchMode=yes -o ConnectTimeout=5 station true 2>/dev/null; then
  echo "PASS: host-alias (ssh station works without a prompt)"
  exit 0
fi

echo "FAIL: host-alias - 'ssh -o BatchMode=yes station true' failed (key not installed, host key not trusted, or bad permissions)"
exit 1
