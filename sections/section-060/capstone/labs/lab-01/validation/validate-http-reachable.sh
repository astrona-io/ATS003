#!/usr/bin/env bash
# Checks that the port 8080 web application is actually reachable end to
# end (listener up AND not firewalled) by requesting it directly, the same
# proof used in the lab's own Verification section.

set -u

code="$(curl -s -o /dev/null -m 5 -w '%{http_code}' http://127.0.0.1:8080/ 2>/dev/null)"

if [[ "$code" =~ ^2 || "$code" =~ ^3 ]]; then
  echo "PASS: http-reachable (http://127.0.0.1:8080/ returned HTTP $code)"
  exit 0
else
  echo "FAIL: http-reachable - http://127.0.0.1:8080/ returned '$code' instead of a 2xx/3xx status (still blocked or app down)"
  exit 1
fi
