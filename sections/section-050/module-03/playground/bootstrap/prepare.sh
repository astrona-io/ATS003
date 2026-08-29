#!/usr/bin/env bash
# OS prep for PLAYGROUND — OpenSSH Server Hardening
# Runs once at startup. Environment preparation ONLY. The whole design is a
# SAFETY net: a second, throwaway sshd on port 2222 with its own config file,
# started deliberately OPEN so hardening has a visible effect, plus two local
# test users. All experiments target :2222; the astrona SSH session on :22 is
# never touched. Nothing here is a graded outcome.
set -euo pipefail

echo "[playground] ssh-hardening-playground: preparing second sshd on :2222..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y --no-install-recommends openssh-server openssh-client || true
fi

# --- test users (playground-only credentials) --------------------------------
groupadd -f sshusers
for spec in "alice alicepass" "bob bobpass"; do
  set -- $spec
  user="$1"; pass="$2"
  id "$user" >/dev/null 2>&1 || useradd -m -s /bin/bash "$user"
  echo "${user}:${pass}" | chpasswd
done
usermod -aG sshusers alice

# a key for alice, so key-only configs are testable from this same VM
install -d -m 700 -o alice -g alice /home/alice/.ssh
if [ ! -f /home/alice/.ssh/id_ed25519 ]; then
  sudo -u alice ssh-keygen -t ed25519 -N '' -f /home/alice/.ssh/id_ed25519 -q
  cp /home/alice/.ssh/id_ed25519.pub /home/alice/.ssh/authorized_keys
  chown alice:alice /home/alice/.ssh/authorized_keys
  chmod 600 /home/alice/.ssh/authorized_keys
fi

# --- the throwaway sshd config, started intentionally permissive -------------
cat > /etc/ssh/sshd_test.conf <<'EOF'
# Throwaway sshd for the hardening playground. Self-contained: it does NOT
# Include /etc/ssh/sshd_config.d/*, so what you see here is what you get.
# Started deliberately OPEN — tighten it and test against port 2222.
Port 2222
PidFile /run/sshd-test.pid
LogLevel VERBOSE

HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# --- the knobs this module is about (all at permissive defaults) ---
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
KbdInteractiveAuthentication no
X11Forwarding yes
AllowTcpForwarding yes
PermitEmptyPasswords no
MaxAuthTries 6
LoginGraceTime 120

Subsystem sftp /usr/lib/openssh/sftp-server

# Append Match blocks below this line.
EOF

# --- run it under systemd, separate from ssh.service ------------------------
cat > /etc/systemd/system/sshd-test.service <<'EOF'
[Unit]
Description=Throwaway OpenSSH server on port 2222 (hardening playground)
After=network.target

[Service]
ExecStartPre=/usr/sbin/sshd -t -f /etc/ssh/sshd_test.conf
ExecStart=/usr/sbin/sshd -D -e -f /etc/ssh/sshd_test.conf
ExecReload=/usr/sbin/sshd -t -f /etc/ssh/sshd_test.conf
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
sshd -t -f /etc/ssh/sshd_test.conf && echo "[playground] sshd_test.conf OK" || echo "[playground] sshd_test.conf WARNING" >&2
systemctl enable --now sshd-test.service 2>/dev/null || true

echo
echo "[playground] listening sockets:"
ss -tlnp 2>/dev/null | grep -E ':22\b|:2222\b' || true

echo
echo "[playground] ready. A throwaway sshd runs on :2222 with config"
echo "[playground] /etc/ssh/sshd_test.conf (currently wide open). Test users:"
echo "[playground]   alice / alicepass   (in group sshusers, has a key at"
echo "[playground]                        /home/alice/.ssh/id_ed25519)"
echo "[playground]   bob   / bobpass"
echo "[playground] Edit sshd_test.conf, 'sudo sshd -t -f /etc/ssh/sshd_test.conf',"
echo "[playground] 'sudo systemctl reload sshd-test', then test:"
echo "[playground]   ssh -p 2222 alice@localhost"
echo "[playground] Do NOT edit /etc/ssh/sshd_config or touch ssh.service on :22 —"
echo "[playground] that carries your astrona session. See docs/overview.md."
