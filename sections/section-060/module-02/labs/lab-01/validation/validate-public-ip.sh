#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Compare the recorded address with the current VM egress.

set -u

path="/opt/course/public_ip"

if [[ ! -f "$path" ]]; then
  echo "FAIL: public_ip - $path does not exist"
  exit 1
fi

actual="$(tr -d '[:space:]' < "$path")"

ipv4_regex='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$'

if [[ ! "$actual" =~ $ipv4_regex ]]; then
  echo "FAIL: public_ip - '$actual' is not a valid IPv4 address"
  exit 1
fi

for octet in "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"; do
  if (( 10#$octet > 255 )); then
    echo "FAIL: public_ip - '$actual' has an out-of-range octet"
    exit 1
  fi
done

private_regex='^(10\.|127\.|169\.254\.|192\.168\.|0\.|172\.(1[6-9]|2[0-9]|3[01])\.)'

if [[ "$actual" =~ $private_regex ]]; then
  echo "FAIL: public_ip - '$actual' looks like a private/reserved address, not a public one"
  exit 1
fi

live=$(curl -4 --fail --silent --show-error --retry 2 --max-time 10 https://ifconfig.me/ip) || {
  echo 'INFRASTRUCTURE: public address lookup is unavailable; retry validation when connectivity returns'
  exit 2
}
live=$(printf '%s' "$live" | tr -d '[:space:]')
if [[ ! "$live" =~ $ipv4_regex ]]; then
  echo 'INFRASTRUCTURE: public address lookup returned an invalid response'
  exit 2
fi
if [[ "$live" != "$actual" ]]; then
  echo "FAIL: public_ip - '$actual' differs from this VM's current egress '$live'; repeat the lookup inside the VM"
  exit 1
fi
echo "PASS: public_ip matches the live VM egress ($actual)"
ASTRONA_STUDENT_SCRIPT
