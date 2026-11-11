#!/usr/bin/env bash
set -euo pipefail
sudo hostnamectl set-hostname web-srv1
sudo hostnamectl set-hostname 'Web Server 1 (Frankfurt)' --pretty
sudo sed -i '/^127\.0\.1\.1/d' /etc/hosts
printf '%s
' '127.0.1.1 web-srv1' | sudo tee -a /etc/hosts
