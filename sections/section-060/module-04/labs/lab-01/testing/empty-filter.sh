#!/usr/bin/env bash
set -euo pipefail
sudo tcpdump -nn -r /opt/course/http.pcap.saved -w /opt/course/http.pcap 'tcp port 9999'
