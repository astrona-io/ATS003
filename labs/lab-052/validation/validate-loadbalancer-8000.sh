#!/usr/bin/env bash
# Checks port 8000 load-balances traffic across both the 1111 and 2222
# backends (round robin or random - either satisfies the scenario).

set -u

seen_1111=0
seen_2222=0

for i in $(seq 1 10); do
  body="$(curl -s http://127.0.0.1:8000/)"
  case "$body" in
    app-1111-root*) seen_1111=1 ;;
    app-2222-root*) seen_2222=1 ;;
  esac
done

if [[ "$seen_1111" -eq 1 && "$seen_2222" -eq 1 ]]; then
  echo "PASS: :8000 load-balances across both the 1111 and 2222 backends"
  exit 0
else
  echo "FAIL: :8000 did not reach both backends over 10 requests (seen_1111=$seen_1111, seen_2222=$seen_2222)"
  exit 1
fi
