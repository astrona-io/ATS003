#!/usr/bin/env bash
# Checks that `chronyc serverstats` runs successfully and reports the
# NTP packet counters, proving chronyd's server side is running and
# answering the chronyc control socket - the same proof `chronyc
# clients` gives on a real multi-host deployment.

set -u

output="$(chronyc serverstats 2>&1)"
status=$?

if [[ $status -ne 0 ]]; then
  echo "FAIL: serverstats - 'chronyc serverstats' failed: $output"
  exit 1
fi

if echo "$output" | grep -qi 'NTP packets received'; then
  echo "PASS: serverstats - chronyc serverstats reports NTP packet counters"
  exit 0
else
  echo "FAIL: serverstats - unexpected output: $output"
  exit 1
fi
