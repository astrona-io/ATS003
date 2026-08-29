#!/usr/bin/env bash
# OS prep for PLAYGROUND — Persistent Network Managers (NetworkManager / nmcli)
# Runs once at startup. Environment preparation ONLY. The safety design: install
# NetworkManager and restrict it to the ONE spare NIC on the isolated
# 192.168.120.0/24 segment. The management interface that carries your SSH
# session stays `unmanaged`, so no nmcli command can drop the session. The spare
# NIC is left with NO connection profile — building persistent profiles is the
# point of the playground.
set -euo pipefail

echo "[playground] networkmanager-nmcli-playground: preparing..."

export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y --no-install-recommends network-manager iproute2 || true
fi

# --- find the spare NIC: up, not loopback, not the default-route interface ---
MGMT_DEV="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')"
SPARE_DEV=""
for dev in $(ip -o link show | awk -F': ' '{print $2}' | cut -d@ -f1 | grep -v '^lo$'); do
  [ "$dev" = "$MGMT_DEV" ] && continue
  # skip anything that already carries a global IPv4 (i.e. also managed elsewhere)
  ip -o -4 addr show dev "$dev" scope global | grep -q inet && continue
  SPARE_DEV="$dev"
  break
done

echo "[playground] management interface : ${MGMT_DEV:-unknown}  (left unmanaged)"
echo "[playground] spare interface       : ${SPARE_DEV:-NOT FOUND}  (NetworkManager will own this)"

# --- restrict NetworkManager to the spare NIC only --------------------------
install -d /etc/NetworkManager/conf.d
if [ -n "$SPARE_DEV" ]; then
  cat > /etc/NetworkManager/conf.d/10-managed.conf <<EOF
# Playground: NetworkManager manages ONLY the spare NIC. Everything else —
# including the interface carrying the SSH session — is unmanaged.
[keyfile]
unmanaged-devices=*,except:interface-name:${SPARE_DEV}
EOF
else
  cat > /etc/NetworkManager/conf.d/10-managed.conf <<'EOF'
# Playground: spare NIC not detected at boot; NetworkManager manages nothing by
# default. Find the spare interface with `ip -br link` and adjust this file's
# `unmanaged-devices=*,except:interface-name:<dev>` line, then
# `sudo systemctl restart NetworkManager`.
[keyfile]
unmanaged-devices=*
EOF
fi

systemctl enable NetworkManager 2>/dev/null || true
systemctl restart NetworkManager 2>/dev/null || systemctl start NetworkManager 2>/dev/null || true
sleep 2

echo
echo "[playground] nmcli general status:"
nmcli general status 2>/dev/null || true
echo
echo "[playground] nmcli device status:"
nmcli device status 2>/dev/null || true

echo
echo "[playground] ready. NetworkManager manages the spare NIC '${SPARE_DEV:-<detect it>}'"
echo "[playground] on the isolated 192.168.120.0/24 segment (no DHCP, no router)."
echo "[playground] It has NO connection profile yet. Build one, e.g.:"
echo "[playground]   sudo nmcli connection add type ethernet con-name lab-static \\"
echo "[playground]       ifname ${SPARE_DEV:-<dev>} ipv4.method manual ipv4.addresses 192.168.120.50/24"
echo "[playground]   sudo nmcli connection up lab-static"
echo "[playground] The management interface is 'unmanaged' — leave it alone. See docs/overview.md."
