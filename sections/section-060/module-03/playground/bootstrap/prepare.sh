#!/usr/bin/env bash
# OS prep for PLAYGROUND — Active Socket Diagnostics (ss)
# Runs once at startup. Environment preparation ONLY: start a spread of sockets
# so every `ss` view has something to show. There is nothing to build or solve
# — reading `ss` on a machine that already has interesting sockets is the point.
set -euo pipefail

echo "[playground] ss-socket-diagnostics-playground: starting sample sockets..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  # socat for the UDP + Unix listeners and the held connection; iproute2 has ss;
  # python3 for the HTTP listeners.
  apt-get install -y --no-install-recommends socat iproute2 python3 || true
fi

mk_unit() {
  local name="$1" desc="$2" after="$3" exec="$4" pre="${5:-}"
  {
    printf '[Unit]\nDescription=%s\n' "$desc"
    [ -n "$after" ] && printf 'After=%s\n' "$after"
    printf '\n[Service]\n'
    [ -n "$pre" ] && printf 'ExecStartPre=%s\n' "$pre"
    printf 'ExecStart=%s\nRestart=always\nDynamicUser=yes\n\n[Install]\nWantedBy=multi-user.target\n' "$exec"
  } > "/etc/systemd/system/${name}.service"
}

# TCP listeners: all-addresses, localhost-only, and IPv6.
mk_unit lab-http-any   "ss playground: TCP listener on 0.0.0.0:8080" "network.target" \
  "/usr/bin/python3 -m http.server 8080 --bind 0.0.0.0"
mk_unit lab-http-local "ss playground: TCP listener on 127.0.0.1:9000" "network.target" \
  "/usr/bin/python3 -m http.server 9000 --bind 127.0.0.1"
mk_unit lab-http-v6    "ss playground: TCP listener on [::1]:8090" "network.target" \
  "/usr/bin/python3 -m http.server 8090 --bind ::1"

# UDP listener on 5514 (drops what it receives).
mk_unit lab-udp "ss playground: UDP listener on 0.0.0.0:5514" "network.target" \
  "/usr/bin/socat -u UDP-RECVFROM:5514,fork OPEN:/dev/null"

# Unix-domain stream listener at a known path.
mk_unit lab-unix "ss playground: Unix listener at /run/lab-app.sock" "network.target" \
  "/usr/bin/socat UNIX-LISTEN:/run/lab-app.sock,fork OPEN:/dev/null" \
  "/bin/rm -f /run/lab-app.sock"

# One long-lived established TCP connection to the localhost-only listener,
# so `ss state established` always has a row to show.
mk_unit lab-estab "ss playground: holds an established TCP connection to 127.0.0.1:9000" \
  "lab-http-local.service" \
  "/bin/sh -c 'exec 3<>/dev/tcp/127.0.0.1/9000; exec sleep infinity'"

systemctl daemon-reload
systemctl enable --now \
  lab-http-any.service lab-http-local.service lab-http-v6.service \
  lab-udp.service lab-unix.service lab-estab.service 2>/dev/null || true

sleep 1
echo
echo "[playground] listening TCP:"
ss -tlnp 2>/dev/null || true
echo
echo "[playground] ready. Sockets in place for ss to show:"
echo "[playground]   TCP  0.0.0.0:8080     (lab-http-any)   - all v4 addresses"
echo "[playground]   TCP  127.0.0.1:9000   (lab-http-local) - localhost only"
echo "[playground]   TCP  [::1]:8090       (lab-http-v6)    - IPv6 loopback"
echo "[playground]   UDP  0.0.0.0:5514     (lab-udp)"
echo "[playground]   UNIX /run/lab-app.sock (lab-unix)"
echo "[playground]   one ESTABLISHED TCP pair on 127.0.0.1:9000 (lab-estab)"
echo "[playground] Start here: ss -tlnp   Then see docs/overview.md."
