#!/usr/bin/env bash
set -euo pipefail
sudo -n python3 - <<'CHECK'
from pathlib import Path
import subprocess
p=Path('/opt/course/http.pcap')
def fail(why):print('FAIL: capture - '+why);raise SystemExit(1)
if not p.is_file():fail('http.pcap is missing')
if p.stat().st_size>10*1024*1024:fail('keep the capture under 10 MiB')
def decode(*args):
 r=subprocess.run(['tcpdump','-nn','-r',str(p),*args],text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=15)
 if r.returncode:fail('file is not a readable packet capture')
 return r.stdout
if decode('not (tcp port 8080)').strip():fail('capture includes traffic outside TCP port 8080')
headers=decode()
if 'Flags [S]' not in headers or 'Flags [S.]' not in headers:fail('capture is missing a TCP handshake')
payload=decode('-A')
if 'GET /token HTTP/1.' not in payload:fail('capture is missing the HTTP request')
if 'HTTP/1.0 200 OK' not in payload:fail('capture is missing the successful response')
token=Path('/srv/lab-capture/token').read_text().strip()
if token not in payload:fail('capture lacks this VM response body; use a full snap length')
print('PASS: filtered HTTP conversation from this VM')
CHECK
