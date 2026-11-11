#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Inspect protected state; user access checks select their target account explicitly.
sudo -n bash <<'GRADER_ROOT'
# Checks that a Netplan file enables DHCP for dhcp0 and refuses routes and DNS.
set -u

if ! sudo python3 - <<'PY'
import glob, sys, yaml
ok = False
for path in glob.glob("/etc/netplan/*.yaml"):
    try:
        data = yaml.safe_load(open(path)) or {}
    except Exception:
        continue
    eth = ((data.get("network") or {}).get("ethernets") or {}).get("dhcp0")
    if not isinstance(eth, dict):
        continue
    ov = eth.get("dhcp4-overrides") or {}
    if eth.get("dhcp4") is True and ov.get("use-routes") is False and ov.get("use-dns") is False:
        ok = True
sys.exit(0 if ok else 1)
PY
then
  echo "FAIL: netplan - no file sets dhcp4: true, use-routes: false and use-dns: false for dhcp0"
  exit 1
fi
echo "PASS: netplan (dhcp0 asks for a lease and refuses routes and DNS)"
exit 0
GRADER_ROOT
ASTRONA_STUDENT_SCRIPT
