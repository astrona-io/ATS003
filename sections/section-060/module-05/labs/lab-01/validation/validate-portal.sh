#!/usr/bin/env bash
# Checks the whole path with a real request and that the service still runs.
set -u

if ! systemctl is-active --quiet portal.service; then
  echo "FAIL: portal - portal.service is not running"
  exit 1
fi

code="$(curl -s -o /dev/null -m 5 -w '%{http_code}' http://portal.lab:8443/ 2>/dev/null)"

if [[ "$code" =~ ^2 || "$code" =~ ^3 ]]; then
  echo "PASS: portal (http://portal.lab:8443/ returned HTTP $code)"
  exit 0
fi

echo "FAIL: portal - http://portal.lab:8443/ returned '${code}' instead of a 2xx/3xx status"
exit 1
