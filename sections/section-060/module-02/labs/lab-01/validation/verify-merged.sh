#!/usr/bin/env bash
set -euo pipefail
sudo -n python3 - <<'CHECK'
import subprocess,yaml
cfg=yaml.safe_load(subprocess.check_output(['netplan','get','ethernets.np0'],text=True)) or {}
if cfg.get('addresses') != ['192.168.130.50/24']:
 print('FAIL: merged config - np0 must contain only 192.168.130.50/24');raise SystemExit(1)
if cfg.get('dhcp4') is not False or cfg.get('renderer')!='networkd':
 print('FAIL: merged config - use static IPv4 with networkd');raise SystemExit(1)
print('PASS: merged Netplan configuration')
CHECK
