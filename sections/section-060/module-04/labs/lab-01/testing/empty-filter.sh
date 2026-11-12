#!/usr/bin/env bash
set -euo pipefail
sudo tcpdump -Z root -nn -r /opt/course/http.saved.pcap -w /opt/course/http.pcap 'tcp port 9999'
