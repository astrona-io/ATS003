#!/usr/bin/env bash
set -euo pipefail
cp /opt/course/http.pcap /opt/course/http.pcap.saved
printf 'GET /token HTTP/1.0\n' > /opt/course/http.pcap
