#!/usr/bin/env bash
set -euo pipefail
sudo -n python3 - <<'CHECK'
import subprocess
from pathlib import Path
def nm(key):return subprocess.check_output(['nmcli','-g',key,'connection','show','lab-static'],text=True).strip()
def require(ok,why):
 if not ok: print('FAIL: profile - '+why);raise SystemExit(1)
try:
 require(nm('connection.interface-name')=='nm0','profile must own nm0')
 require(nm('ipv4.method')=='manual','manual IPv4 required')
 require(nm('ipv4.addresses')=='192.168.120.50/24','saved address is incorrect')
 require(nm('connection.autoconnect')=='yes','autoconnect is disabled')
 require(nm('ipv4.never-default')=='yes','practice interface must not become the default route')
 uuid=nm('connection.uuid')
 files = list(Path('/etc/NetworkManager/system-connections').glob('*')) + list(Path('/etc/netplan').glob('*.yaml'))
 require(any(uuid in f.read_text() for f in files if f.is_file()),'profile is not saved on disk')
except subprocess.CalledProcessError:
 print('FAIL: profile - lab-static is missing');raise SystemExit(1)
print('PASS: saved NetworkManager profile')
CHECK
