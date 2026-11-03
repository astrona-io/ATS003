#!/usr/bin/env bash
# Bootstrap: creates the users cadet and pilot, a throwaway sshd on
# 127.0.0.1:2222 and a loopback-only web service on 127.0.0.1:8081. The real
# sshd on port 22 that carries the astrona session is not touched.
set -eu

for spec in "cadet cadetpass" "pilot pilotpass"; do
  set -- $spec
  user="$1"; pass="$2"
  id -u "$user" >/dev/null 2>&1 || sudo useradd -m -s /bin/bash "$user"
  echo "${user}:${pass}" | sudo chpasswd
  sudo passwd -u "$user" >/dev/null 2>&1 || true
done

sudo tee /etc/ssh/sshd_station.conf > /dev/null <<'CONF'
Port 2222
ListenAddress 127.0.0.1
PidFile /run/sshd-station.pid
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
PasswordAuthentication yes
PubkeyAuthentication yes
KbdInteractiveAuthentication no
AllowTcpForwarding yes
AllowUsers pilot
Subsystem sftp /usr/lib/openssh/sftp-server
CONF

sudo tee /etc/systemd/system/sshd-station.service > /dev/null <<'UNIT'
[Unit]
Description=Throwaway OpenSSH server on port 2222 (client lab)
After=network.target

[Service]
ExecStartPre=/usr/sbin/sshd -t -f /etc/ssh/sshd_station.conf
ExecStart=/usr/sbin/sshd -D -e -f /etc/ssh/sshd_station.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

sudo install -d /opt/station-data
echo "station data online" | sudo tee /opt/station-data/index.html > /dev/null
sudo tee /etc/systemd/system/station-data.service > /dev/null <<'UNIT'
[Unit]
Description=Lab web service on 127.0.0.1:8081
After=network.target

[Service]
WorkingDirectory=/opt/station-data
ExecStart=/usr/bin/python3 -m http.server 8081 --bind 127.0.0.1
Restart=on-failure
DynamicUser=yes

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now sshd-station.service station-data.service
