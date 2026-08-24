#!/usr/bin/env bash
# Confirms PasswordAuthentication is disabled for everyone except elena,
# using `sshd -T -C` to read the effective per-connection config sshd would
# actually apply -- the authoritative way to check Match block resolution.

set -u

host="$(hostname)"
pass=true

elena_val="$(sudo sshd -T -C user=elena,host="${host}",addr=127.0.0.1 2>/dev/null | grep -i '^passwordauthentication' | awk '{print $2}')"
if [[ "$elena_val" != "yes" ]]; then
  echo "FAIL: passwordauth-config - elena effective passwordauthentication = '$elena_val', expected 'yes'"
  pass=false
else
  echo "PASS: passwordauth-config - elena effective passwordauthentication = 'yes'"
fi

victor_val="$(sudo sshd -T -C user=victor,host="${host}",addr=127.0.0.1 2>/dev/null | grep -i '^passwordauthentication' | awk '{print $2}')"
if [[ "$victor_val" != "no" ]]; then
  echo "FAIL: passwordauth-config - victor effective passwordauthentication = '$victor_val', expected 'no'"
  pass=false
else
  echo "PASS: passwordauth-config - victor effective passwordauthentication = 'no'"
fi

if $pass; then
  exit 0
else
  exit 1
fi
