# Solution

## Step 0: Inspect the current interface and resolve the gateway

```bash
ip -br addr show
ip route show
getent hosts astrona-ats-003-lab-060-gateway
```

Confirm your own primary interface/address before adding anything — interface names and subnet assignments should never be assumed on an exam target, always confirmed. `getent hosts astrona-ats-003-lab-060-gateway` resolves the gateway VM's real address on the shared lab network; keep that address handy — it's `$GW` below.

## Step 1: Add the route live (ephemeral) first

```bash
GW="$(getent hosts astrona-ats-003-lab-060-gateway | awk '{print $1}')"
sudo ip route add 10.10.30.0/24 via "$GW"
```

Check `man ip-route` — the general form is `ip route add DESTINATION via GATEWAY [dev INTERFACE]`. `10.10.30.0/24` is the destination network being reached, `via "$GW"` names the next-hop router that knows how to get there. `dev` is optional when there's exactly one interface that could plausibly reach the gateway's address, which is the case in this lab; on a genuinely multi-homed host (the exam's original `eth0`/`eth1` framing) you'd pin it explicitly with `dev eth1` to remove any ambiguity.

If a route to this destination already exists and you need to change it rather than error out on a duplicate, use `ip route replace` instead of `add` — check `man ip-route` for the distinction; `add` fails loudly if a matching route already exists, while `replace` overwrites it unconditionally.

## Step 2: Verify with `ip route get` before assuming anything

```bash
ip route get 10.10.30.1
```

Check `man ip-route`, search `/get` — this subcommand asks the kernel which route it would actually select for a destination, without sending any packet. Expected output (with `$GW` being the gateway VM's resolved address):

```text
10.10.30.1 via <GW> dev eth0 src <your-address> uid 1000
    cache
```

The `via` shown here must match `$GW` exactly — if it instead shows a different gateway, something is wrong (a more specific conflicting route, or a typo in the destination CIDR or gateway address).

## Step 3: Understand the default-route interaction

```bash
ip route show default
```

If this host has a default route (e.g. `default via 192.168.10.1 dev eth0`), that route only ever matches destinations *not* covered by any more specific route. Because `10.10.30.0/24` is a `/24` (more specific than the default's `/0`), the kernel's longest-prefix-match logic always prefers your new route for anything inside `10.10.30.0/24`, regardless of the default route's existence — the two coexist without conflict.

## Step 4: Persist the route — Netplan path

```yaml
# /etc/netplan/60-route.yaml
network:
  version: 2
  ethernets:
    eth0:
      routes:
        - to: 10.10.30.0/24
          via: 10.10.20.1   # replace with $GW, the gateway VM's resolved address
```

Check `man 5 netplan` and search for `routes:` — it's a list under the interface, with `to`/`via` (and optionally `metric`) keys, distinct from the `addresses:` key used for the interface's own IPs. Netplan routes need a literal IP, not a hostname — resolve `$GW` first and hardcode the actual value, don't leave a placeholder. `netplan apply` re-renders and applies the change:

```bash
sudo netplan generate
sudo netplan apply
```

## Step 5: Persist the route — NetworkManager path

```bash
CONN="$(nmcli -t -f NAME con show --active | head -n1)"
sudo nmcli con mod "$CONN" +ipv4.routes "10.10.30.0/24 $GW"
sudo nmcli con up "$CONN"
```

Check `man nmcli` and search `/ipv4.routes` — the property value format is `destination/prefix next-hop [metric]`, space-separated, as a string. As with addresses, the `+` prefix appends to any existing routes on that connection rather than replacing the whole list — omitting it would wipe out any other static routes already configured on the interface.

## Step 6: Persist the route — legacy RHEL-family scripts (if not NetworkManager/Netplan)

```bash
echo "10.10.30.0/24 via $GW" | sudo tee /etc/sysconfig/network-scripts/route-eth0
```

This older-style file format (still supported on some RHEL-family systems for backward compatibility) is read by the legacy network service at interface-up time. It's declining in relevance as NetworkManager becomes the default everywhere, but it's worth recognizing on a system that still uses it.

## Verification

```bash
ip route show 10.10.30.0/24
```

Expected:

```text
10.10.30.0/24 via <GW>
```

```bash
ip route get 10.10.30.1
```

Expected `via` matching the same `$GW`.

Real end-to-end proof — this only works if the gateway VM is actually forwarding, not just present in this host's routing table:

```bash
ping -c2 10.10.30.1
traceroute 10.10.30.1
```

`10.10.30.1` is the gateway VM's own address inside the partner subnet it fronts — a reply proves the packet actually left this host, crossed to the gateway VM, and got a real response back, not just that an entry exists in `ip route show`. `traceroute`'s first hop should be `$GW`.

Reboot-survival check (if the environment allows a reboot):

```bash
sudo reboot
# after reboot:
ip route show 10.10.30.0/24
```

The route should reappear automatically without re-running `ip route add`.

## Command Summary

```bash
ip -br addr show
ip route show
GW="$(getent hosts astrona-ats-003-lab-060-gateway | awk '{print $1}')"

sudo ip route add 10.10.30.0/24 via "$GW"
ip route get 10.10.30.1
ip route show default

# Netplan path (use $GW's actual resolved value, not a placeholder):
sudo $EDITOR /etc/netplan/60-route.yaml
sudo netplan generate
sudo netplan apply

# NetworkManager path:
CONN="$(nmcli -t -f NAME con show --active | head -n1)"
sudo nmcli con mod "$CONN" +ipv4.routes "10.10.30.0/24 $GW"
sudo nmcli con up "$CONN"

# Legacy RHEL-family path:
echo "10.10.30.0/24 via $GW" | sudo tee /etc/sysconfig/network-scripts/route-eth0

ip route show 10.10.30.0/24
ping -c2 10.10.30.1
traceroute 10.10.30.1
```
