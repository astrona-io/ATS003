#!/usr/bin/env bash
set -euo pipefail
cp /opt/course/http.pcap /opt/course/http.saved.pcap
printf 'GET /token HTTP/1.0\n' > /opt/course/http.pcap
