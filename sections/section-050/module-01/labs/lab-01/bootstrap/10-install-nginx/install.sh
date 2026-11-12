#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# Bootstrap init: nginx ships in the base LFCS image; this just makes sure
# the service is enabled and running.

set -eu

missing=()
for package in nginx; do
  dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q 'install ok installed' || missing+=("$package")
done
if [ "${#missing[@]}" -gt 0 ]; then
  sudo apt-get update -y
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
fi

sudo systemctl enable nginx
sudo systemctl start nginx
ASTRONA_STUDENT_SCRIPT
