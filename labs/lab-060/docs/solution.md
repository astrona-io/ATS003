# Solution

## Step 0: Inspect the current interfaces and routing table

```bash
ip -br addr show
ip route show
```

Confirm `eth0` really has 192.168.10.0/24 and `eth1` really has 10.10.20.0/24 before adding anything — interface names and subnet assignments should never be assumed on an exam target, always confirmed.

## Step 1: Add the route live (ephemeral) first

```bash
sudo ip route add 10.10.30.0/24 via 10.10.20.1 dev eth1
```

Check `man ip-route` — the general form is `ip route add DESTINATION via GATEWAY dev INTERFACE`. `10.10.30.0/24` is the destination network being reached, `via 10.10.20.1` names the next-hop router that knows how to get there, and `dev eth1` pins the outbound interface explicitly — technically the kernel could often infer the device from the gateway's subnet, but specifying it removes any ambiguity, which matters on a multi-homed host with more than one interface that could plausibly reach 10.10.20.1's subnet indirectly.

If a route to this destination already exists and you need to change it rather than error out on a duplicate, use `ip route replace` instead of `add` — check `man ip-route` for the distinction; `add` fails loudly if a matching route already exists, while `replace` overwrites it unconditionally.

## Step 2: Verify with `ip route get` before assuming anything

```bash
ip route get 10.10.30.5
```

Check `man ip-route`, search `/get` — this subcommand asks the kernel which route it would actually select for a destination, without sending any packet. Expected output:

```text
10.10.30.5 via 10.10.20.1 dev eth1 src 10.10.20.X uid 1000
    cache
```

The `via`/`dev` shown here must match exactly what you configured — if it instead shows a route via `eth0` or a different gateway, something is wrong (a more specific conflicting route, or a typo in the destination CIDR).

## Step 3: Understand the default-route interaction

```bash
ip route show default
```

If data-001 has a default route (e.g. `default via 192.168.10.1 dev eth0`), that route only ever matches destinations *not* covered by any more specific route. Because `10.10.30.0/24` is a `/24` (more specific than the default's `/0`), the kernel's longest-prefix-match logic always prefers your new route for anything inside `10.10.30.0/24`, regardless of the default route's existence — the two coexist without conflict.

## Step 4: Persist the route — Netplan path

```yaml
# /etc/netplan/60-data-001-eth1.yaml
network:
  version: 2
  ethernets:
    eth1:
      addresses:
        - 10.10.20.X/24
      routes:
        - to: 10.10.30.0/24
          via: 10.10.20.1
```

Check `man 5 netplan` and search for `routes:` — it's a list under the interface, with `to`/`via` (and optionally `metric`) keys, distinct from the `addresses:` key used for the interface's own IPs. `netplan apply` re-renders and applies the change:

```bash
sudo netplan generate
sudo netplan apply
```

## Step 5: Persist the route — NetworkManager path

```bash
sudo nmcli con mod "eth1" +ipv4.routes "10.10.30.0/24 10.10.20.1"
sudo nmcli con up "eth1"
```

Check `man nmcli` and search `/ipv4.routes` — the property value format is `destination/prefix next-hop [metric]`, space-separated, as a string. As with addresses, the `+` prefix appends to any existing routes on that connection rather than replacing the whole list — omitting it would wipe out any other static routes already configured on `eth1`.

## Step 6: Persist the route — legacy RHEL-family scripts (if not NetworkManager/Netplan)

```bash
# /etc/sysconfig/network-scripts/route-eth1
10.10.30.0/24 via 10.10.20.1 dev eth1
```

This older-style file format (still supported on some RHEL-family systems for backward compatibility) is read by the legacy network service at interface-up time. It's declining in relevance as NetworkManager becomes the default everywhere, but it's worth recognizing on a system that still uses it.

## Verification

```bash
ip route show 10.10.30.0/24
```

Expected:

```text
10.10.30.0/24 via 10.10.20.1 dev eth1
```

```bash
ip route get 10.10.30.5
```

Expected:

```text
10.10.30.5 via 10.10.20.1 dev eth1 src 10.10.20.X
```

Reboot-survival check (if the environment allows a reboot):

```bash
sudo reboot
# after reboot:
ip route show 10.10.30.0/24
```

The route should reappear automatically without re-running `ip route add`.

```bash
traceroute 10.10.30.5
```

The first hop shown should be `10.10.20.1`, confirming the route is actually used for outbound packets, not just present in the table.

## Command Summary

```bash
ip -br addr show
ip route show

sudo ip route add 10.10.30.0/24 via 10.10.20.1 dev eth1
ip route get 10.10.30.5
ip route show default

# Netplan path:
sudo $EDITOR /etc/netplan/60-data-001-eth1.yaml
sudo netplan generate
sudo netplan apply

# NetworkManager path:
sudo nmcli con mod "eth1" +ipv4.routes "10.10.30.0/24 10.10.20.1"
sudo nmcli con up "eth1"

# Legacy RHEL-family path:
echo "10.10.30.0/24 via 10.10.20.1 dev eth1" | sudo tee /etc/sysconfig/network-scripts/route-eth1

ip route show 10.10.30.0/24
traceroute 10.10.30.5
```
