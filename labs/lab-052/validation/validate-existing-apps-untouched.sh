#!/usr/bin/env bash
# Checks the pre-existing, off-limits apps on ports 1111 and 2222 (bootstrap
# apps) still serve their original content, proving their config files
# were never edited.

set -u

fail=0

app1111="$(curl -s http://127.0.0.1:1111/)"
if [[ "$app1111" == "app-1111-root" ]]; then
  echo "PASS: app on port 1111 still serves its original content"
else
  echo "FAIL: app on port 1111 - got '$app1111', expected 'app-1111-root' (its config may have been modified)"
  fail=1
fi

app2222="$(curl -s http://127.0.0.1:2222/)"
if [[ "$app2222" == "app-2222-root" ]]; then
  echo "PASS: app on port 2222 still serves its original content"
else
  echo "FAIL: app on port 2222 - got '$app2222', expected 'app-2222-root' (its config may have been modified)"
  fail=1
fi

special="$(curl -s http://127.0.0.1:2222/special)"
if [[ "$special" == "app-2222-special" ]]; then
  echo "PASS: /special path on port 2222 still serves its original content"
else
  echo "FAIL: /special on port 2222 - got '$special', expected 'app-2222-special' (its config may have been modified)"
  fail=1
fi

exit "$fail"
