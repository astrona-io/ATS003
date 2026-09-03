# Question

Solve this question on: `terminal`

## Scenario

This is the Section 010 capstone. It pulls together interface addressing,
persistent network configuration, and local name resolution into one task,
with no step-by-step guidance.

The host `app-srv1` must be reachable on a dedicated secondary address before
the data team points their pipeline configuration at it. The machine's
primary interface already carries its management address over DHCP; that
address and its default route carry your current session — **do not remove
or replace them.** Add the new addressing beside the management address and
make it permanent.

## Tasks

Work on the **primary network interface** — the one that holds the default
route (`ip -o -4 route show to default` names it).

1. **Secondary IPv4.** Add the static IPv4 address `192.168.10.71/24` to
   that interface, in addition to the existing management address. The
   interface must end up with at least two IPv4 addresses.

2. **Static IPv6.** Add the static IPv6 address `fd00:10::70/64` from the
   site's unique-local (ULA) range to the same interface. It must reach
   **global scope** with duplicate-address detection finished — not
   `tentative`, not `dadfailed` — and must answer a local
   `ping -6 fd00:10::70`.

3. **Persistence.** Declare both the secondary IPv4 and the IPv6 address in
   on-disk network configuration — a file under `/etc/netplan/` or a
   NetworkManager connection profile — so a reboot brings them back. An
   address added only with `ip addr add` does **not** count.

4. **Name resolution.** In `/etc/hosts`, map `app-srv1` to `192.168.10.71`
   so both directions resolve:
   - `getent hosts app-srv1` returns `192.168.10.71` (forward), and
   - `getent hosts 192.168.10.71` returns `app-srv1` (reverse).
