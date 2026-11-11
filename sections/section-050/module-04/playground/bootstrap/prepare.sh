#!/usr/bin/env bash
# Match the account used by astrona ssh, including its home and permissions.
sudo -H -u student bash <<'ASTRONA_STUDENT_SCRIPT'
# OS prep for PLAYGROUND — OpenSSH Client
# Runs once at startup, as a regular user with passwordless sudo (the LFCS
# base image). openssh-server, openssh-client and curl ship in the base image.
# Safety design: two throwaway sshd services on ports 2222 and 2223 with their
# own config files. The real sshd on port 22, which carries the astrona
# session, is never touched.
set -euo pipefail

echo "[playground] ssh-client-playground: preparing..."

# --- users (playground-only credentials) -------------------------------------
for spec in "cadet cadetpass" "pilot pilotpass"; do
  set -- $spec
  user="$1"; pass="$2"
  id "$user" >/dev/null 2>&1 || sudo useradd -m -s /bin/bash "$user"
  echo "${user}:${pass}" | sudo chpasswd
  sudo passwd -u "$user" >/dev/null 2>&1 || true
done

# --- two throwaway sshd services ---------------------------------------------
write_sshd_service() {
  local name="$1" port="$2"
  sudo tee "/etc/ssh/sshd_${name}.conf" > /dev/null <<CONF
# Throwaway sshd for the OpenSSH client playground (${name}, port ${port}).
Port ${port}
ListenAddress 127.0.0.1
PidFile /run/sshd-${name}.pid
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
PasswordAuthentication yes
PubkeyAuthentication yes
KbdInteractiveAuthentication no
AllowTcpForwarding yes
AllowUsers pilot
Subsystem sftp /usr/lib/openssh/sftp-server
CONF
  sudo tee "/etc/systemd/system/sshd-${name}.service" > /dev/null <<UNIT
[Unit]
Description=Throwaway OpenSSH server "${name}" on port ${port} (client playground)
After=network.target

[Service]
ExecStartPre=/usr/sbin/sshd -t -f /etc/ssh/sshd_${name}.conf
ExecStart=/usr/sbin/sshd -D -e -f /etc/ssh/sshd_${name}.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
}
write_sshd_service station 2222
write_sshd_service relay 2223

# --- a web service only reachable on loopback ----------------------------------
sudo install -d /opt/station-data
echo "station data online" | sudo tee /opt/station-data/index.html > /dev/null
sudo tee /etc/systemd/system/station-data.service > /dev/null <<'UNIT'
[Unit]
Description=Playground web service on 127.0.0.1:8081
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
sudo systemctl enable --now sshd-station.service sshd-relay.service station-data.service 2>/dev/null || true

sleep 1
echo
echo "[playground] listening sockets:"
sudo ss -tlnp 2>/dev/null | grep -E ':22\b|:2222\b|:2223\b|:8081\b' || true

echo
echo "[playground] ready. Work as the visitor: sudo -iu cadet"
echo "[playground]   station sshd : localhost:2222 (user pilot / pilotpass)"
echo "[playground]   relay sshd   : localhost:2223 (jump host, user pilot)"
echo "[playground]   web service  : 127.0.0.1:8081 (loopback only)"
echo "[playground] Do NOT change the real sshd on port 22. See docs/overview.md."
ASTRONA_STUDENT_SCRIPT
