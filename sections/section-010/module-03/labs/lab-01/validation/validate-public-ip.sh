#!/usr/bin/env bash
# Checks /opt/course/public_ip holds a plausible public (non-private) IPv4
# address. Cross-checks against a live HTTP/DNS lookup when outbound network
# access is available at validation time, but does not hard-fail on network
# issues -- the grading VM's path to the internet may differ from the
# student's, so an exact live-match is treated as a bonus note, not a
# requirement.

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

live=""
if command -v curl >/dev/null 2>&1; then
  live="$(curl -s -m 5 ifconfig.me 2>/dev/null | tr -d '[:space:]' || true)"
  if [[ -z "$live" ]]; then
    live="$(curl -s -m 5 icanhazip.com 2>/dev/null | tr -d '[:space:]' || true)"
  fi
fi
if [[ -z "$live" ]] && command -v dig >/dev/null 2>&1; then
  live="$(dig +short +time=3 +tries=1 myip.opendns.com @resolver1.opendns.com 2>/dev/null | tr -d '[:space:]' || true)"
fi

if [[ -n "$live" && "$live" != "$actual" ]]; then
  echo "PASS: public_ip ($path = '$actual', valid public-looking IPv4; note: live re-check returned '$live' -- may legitimately differ if this VM's NAT egress differs from the student's)"
  exit 0
fi

echo "PASS: public_ip ($path = '$actual')"
exit 0
