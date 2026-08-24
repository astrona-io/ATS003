#!/usr/bin/env bash
# Checks port 8001 reverse-proxies every request through to the 2222 app's
# /special path (fixed-target proxy_pass, not a client-visible redirect).

set -u

fail=0

root="$(curl -s http://127.0.0.1:8001/)"
other="$(curl -s http://127.0.0.1:8001/anything-else)"

if [[ "$root" == app-2222-special* ]]; then
  echo "PASS: GET :8001/ proxies through to the 2222 app's /special path"
else
  echo "FAIL: GET :8001/ - got '$root', expected content starting with 'app-2222-special'"
  fail=1
fi

if [[ "$other" == app-2222-special* ]]; then
  echo "PASS: GET :8001/anything-else also lands on the 2222 app's /special path"
else
  echo "FAIL: GET :8001/anything-else - got '$other', expected content starting with 'app-2222-special'"
  fail=1
fi

# Make sure it's genuinely proxying (200), not a 3xx redirect back to the client.
status="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8001/)"
if [[ "$status" == "200" ]]; then
  echo "PASS: GET :8001/ returns 200 directly (transparent proxy, not a redirect)"
else
  echo "FAIL: GET :8001/ returned HTTP $status, expected 200 (a 3xx here suggests return 301 was used instead of proxy_pass)"
  fail=1
fi

exit "$fail"
