#!/usr/bin/env bash
set -euo pipefail
if [ "$(cat /opt/course/request-path 2>/dev/null || true)" != /token ]; then echo 'FAIL: evidence - request-path must identify the captured URI'; exit 1; fi
if ! cmp -s /opt/course/response-token /srv/lab-capture/token; then echo 'FAIL: evidence - response-token differs from the server response'; exit 1; fi
echo 'PASS: decoded request and response'
