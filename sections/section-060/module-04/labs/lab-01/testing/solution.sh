#!/usr/bin/env bash
set -euo pipefail
sudo timeout --signal=INT 8 tcpdump -Z root -i lo -nn -s 0 -U -w /opt/course/http.pcap 'tcp port 8080' || test "$?" -eq 124
sudo chown student:student /opt/course/http.pcap
tcpdump -nn -A -r /opt/course/http.pcap > /opt/course/decoded.txt
python3 - <<'DECODE'
from pathlib import Path
import re
text = Path('/opt/course/decoded.txt').read_text(errors='replace')
request = re.search(r'GET ([^ ]+) HTTP/1[.]', text)
assert request, 'No HTTP request captured'
Path('/opt/course/request-path').write_text(request[1] + chr(10))
token = re.search(r'[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}', text)
assert token, 'No response token captured'
Path('/opt/course/response-token').write_text(token[0] + chr(10))
DECODE
