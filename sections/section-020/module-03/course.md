# Multi-Interface Static Routing

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-020/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-03/playground
> astrona destroy static-routing-playground
> ```

A Linux machine uses its **routing table** to decide where to send Layer 3 network packets. **Layer 3** is the layer that moves packets between networks using IP addresses; a **route** is one entry in the table that says "traffic for this destination goes out that way."

For every outgoing packet, Linux must work out:

- Which route matches the destination.
- Which network interface should carry the packet.
- Whether the destination is directly reachable, or must go through a gateway.
- Which source IP address to use.

This matters most when a machine has several network interfaces connected to different networks.

## Reading network prefixes

Routes are written with a network address and a **prefix length**, such as `10.0.0.0/24`. The number after the slash is how many leading bits are fixed:

- `10.0.0.0/24` — the first 24 bits are the network; the last 8 vary. Covers `10.0.0.0`–`10.0.0.255`.
- `172.16.0.0/16` — the first 16 bits are fixed. Covers `172.16.0.0`–`172.16.255.255`.
- `0.0.0.0/0` — nothing is fixed. Matches every IPv4 address. This is the **default route**.

A larger prefix number means a smaller, more specific range. This idea drives most of route selection, so it is worth being comfortable with before continuing.

## Key terms

| Term | Meaning in this chapter |
|---|---|
| **Route** | One routing-table entry: a destination prefix plus how to reach it (interface, and a gateway if needed). |
| **Connected route** | A route Linux adds automatically for a network attached to one of its own interfaces. No gateway needed. |
| **Gateway / next hop** | A router on a directly connected network that forwards packets toward a network you cannot reach directly. |
| **Default route** | The `0.0.0.0/0` route, used when nothing more specific matches. |
| **Metric** | A preference number on a route. Lower is preferred when two routes have the same prefix. |
| **Neighbour table** | Linux's record of which MAC address belongs to which local IP (built by ARP for IPv4). |
| **Asymmetric routing** | When replies come back through a different interface or path than the one the request left by. |
| **Policy routing** | Choosing a route by more than the destination — for example by source address or incoming interface. |

## A machine with multiple interfaces

Consider a Linux machine with two interfaces:

```text
eth0: 192.168.1.50/24
eth1: 10.0.0.50/24
```

They connect the machine to two different networks:

```text
192.168.1.0/24 ─── eth0 ─── Linux host ─── eth1 ─── 10.0.0.0/24
```

Linux normally creates a directly connected route when an IP address is assigned to an interface. The routing table may then contain:

```text
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.50
10.0.0.0/24 dev eth1 proto kernel scope link src 10.0.0.50
```

These routes tell Linux that both networks are directly reachable.

## Viewing the routing table

Display the IPv4 routing table:

```bash
ip route show
```

The shorter form produces the same result:

```bash
ip route
```

Example output:

```text
default via 192.168.1.1 dev eth0
10.0.0.0/24 dev eth1 proto kernel scope link src 10.0.0.50
172.16.0.0/16 via 10.0.0.1 dev eth1
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.50
```

This table contains:

- A default route through `192.168.1.1`.
- A directly connected route for `10.0.0.0/24`.
- A static route to `172.16.0.0/16`.
- A directly connected route for `192.168.1.0/24`.

Display the IPv6 routing table separately:

```bash
ip -6 route show
```

> [!TIP]
> **Try it — see the routing table the playground starts with**
>
> ```sh
> ip route show
> ```
>
> Expect something like:
>
> ```text
> default via 10.10.0.1 dev enp0s1 proto dhcp src 10.10.0.20 metric 100
> 10.0.0.0/24 dev enp0s2 proto kernel scope link src 10.0.0.50
> 10.10.0.0/24 dev enp0s1 proto kernel scope link src 10.10.0.20 metric 100
> 192.168.70.0/24 dev enp0s3 proto kernel scope link src 192.168.70.50
> ```
>
> Three `proto kernel scope link` lines are connected routes — one per addressed interface, added automatically. The `default` line belongs to the management interface. Interface names and the management network vary; the two lab networks are `10.0.0.0/24` and `192.168.70.0/24`.

## Understanding a connected route

Consider this route:

```text
10.0.0.0/24 dev eth1 proto kernel scope link src 10.0.0.50
```

Its fields mean:

- `10.0.0.0/24` — the destination network.
- `dev eth1` — the outgoing interface.
- `proto kernel` — Linux created the route automatically.
- `scope link` — the network is directly reachable, no gateway required.
- `src 10.0.0.50` — the preferred source address for traffic using this route.

No gateway is needed because the destination network is directly connected to `eth1`.

## Understanding a static route

A **static route** is one you configure by hand to tell Linux how to reach a network that is not directly connected.

Example:

```bash
sudo ip route add 172.16.0.0/16 via 10.0.0.1 dev eth1
```

This tells Linux:

> To reach an address in `172.16.0.0/16`, send the packet to gateway `10.0.0.1` through `eth1`.

The parts are:

- `172.16.0.0/16` — the destination network.
- `via 10.0.0.1` — the next-hop router.
- `dev eth1` — the outgoing interface.

`sudo` is required because changing the routing table is a privileged operation. The gateway must normally be reachable on a network directly connected to the chosen interface — here `10.0.0.1` has to be inside `eth1`'s local `10.0.0.0/24`. A `via` address that is not on-link is rejected with `Error: Nexthop has invalid gateway`.

A second example routes through `eth0`:

```bash
sudo ip route add 10.50.0.0/16 via 192.168.1.254 dev eth0
```

> [!TIP]
> **Try it — add a static route and ask Linux to resolve it**
>
> Use the interface name on the `10.0.0.0/24` segment (the examples call it `enp0s2`). `10.0.0.1` is on-link there, so the add succeeds even though no router actually sits at that address in the playground.
>
> ```sh
> sudo ip route add 172.16.0.0/16 via 10.0.0.1 dev enp0s2
> ip route show
> ip route get 172.16.50.1
> ```
>
> Expect something like:
>
> ```text
> 172.16.0.0/16 via 10.0.0.1 dev enp0s2
> ...
> 172.16.50.1 via 10.0.0.1 dev enp0s2 src 10.0.0.50 uid 1000
>     cache
> ```
>
> The route appears in the table, and `ip route get` reports it would leave via `enp0s2` toward `10.0.0.1` using source `10.0.0.50`. `ip route get` is a lookup only — it sends no packet — which is why it works with a gateway nothing answers.

## Understanding the default route

A default route is used when no more specific route matches.

Example:

```text
default via 192.168.1.1 dev eth0
```

The word `default` stands for `0.0.0.0/0`, which can match any IPv4 destination — but a more specific route always wins. For example:

- Traffic for `192.168.1.20` uses the connected `192.168.1.0/24` route.
- Traffic for `172.16.100.5` uses the static `172.16.0.0/16` route.
- Traffic for `8.8.8.8` uses the default route.

A host normally has one default route. Linux can hold more than one, distinguished by metric or by policy routing.

## Longest-prefix matching

When several routes match a destination, Linux normally picks the one with the **longest matching prefix** — the most specific.

Consider these routes:

```text
default via 192.168.1.1 dev eth0
172.16.0.0/16 via 10.0.0.1 dev eth1
172.16.100.0/24 via 192.168.1.254 dev eth0
```

For `172.16.100.5`, both `172.16.0.0/16` and `172.16.100.0/24` match. The `/24` is more specific, so Linux selects:

```text
172.16.100.0/24 via 192.168.1.254 dev eth0
```

The default route has the shortest possible prefix, `/0`, so it is only chosen when nothing else matches.

> [!TIP]
> **Try it — watch a more specific route win**
>
> With the `172.16.0.0/16` route from before still in place, add a `/24` inside it that points the other way, then compare two lookups:
>
> ```sh
> sudo ip route add 172.16.100.0/24 via 192.168.70.1 dev enp0s3
> ip route get 172.16.100.5
> ip route get 172.16.5.5
> ```
>
> Expect something like:
>
> ```text
> 172.16.100.5 via 192.168.70.1 dev enp0s3 src 192.168.70.50 uid 1000
> 172.16.5.5 via 10.0.0.1 dev enp0s2 src 10.0.0.50 uid 1000
> ```
>
> `172.16.100.5` matches both routes and takes the `/24` out `enp0s3`; `172.16.5.5` matches only the `/16` and takes that out `enp0s2`. Same destination prefix family, different interface, decided purely by prefix length.

## Route metrics

When several routes have the **same** destination prefix, a **metric** says which is preferred. Lower is normally better.

Example:

```text
default via 192.168.1.1 dev eth0 metric 100
default via 10.0.0.1 dev eth1 metric 200
```

Here the `eth0` route is preferred; the `eth1` route is a standby that may be used if the first is removed.

Create a route with a metric:

```bash
sudo ip route add default via 10.0.0.1 dev eth1 metric 200
```

A lower metric does not by itself give full failover. Linux still has to notice that the preferred route or its interface is gone before it moves to the other one.

> [!TIP]
> **Try it — add a higher-metric second default and see which one wins**
>
> **Warning:** do not touch the existing low-metric default on the management interface — that route carries your SSH session. Only add and later remove the extra one below.
>
> ```sh
> sudo ip route add default via 10.0.0.1 dev enp0s2 metric 500
> ip route show default
> ip route get 8.8.8.8
> ```
>
> Expect something like:
>
> ```text
> default via 10.10.0.1 dev enp0s1 proto dhcp src 10.10.0.20 metric 100
> default via 10.0.0.1 dev enp0s2 metric 500
> ...
> 8.8.8.8 via 10.10.0.1 dev enp0s1 src 10.10.0.20 uid 1000
> ```
>
> Both defaults sit in the table, ordered by metric, and the lower-metric one is still chosen. Remove the one you added with `sudo ip route del default via 10.0.0.1 dev enp0s2 metric 500`.

## Inspecting the route to a destination

`ip route get` asks Linux which route it would use for one destination:

```bash
ip route get 8.8.8.8
```

Example output:

```text
8.8.8.8 via 192.168.1.1 dev eth0 src 192.168.1.50 uid 1000
```

Meaning:

- `8.8.8.8` — the destination.
- `192.168.1.1` — the selected gateway.
- `eth0` — the selected outgoing interface.
- `192.168.1.50` — the selected source address.

For a destination reached through a static route:

```bash
ip route get 172.16.100.5
```

```text
172.16.100.5 via 10.0.0.1 dev eth1 src 10.0.0.50
```

`ip route get` performs a route lookup only. It does not send a packet.

## Selecting a source address

A multi-interface host has several IP addresses, and Linux must pick a source address for each outgoing packet. By default it uses the address on the interface the route selected:

```text
eth0: 192.168.1.50/24   →  traffic out eth0 uses 192.168.1.50
eth1: 10.0.0.50/24      →  traffic out eth1 uses 10.0.0.50
```

A preferred source can be pinned on a static route:

```bash
sudo ip route add 172.16.0.0/16 \
  via 10.0.0.1 \
  dev eth1 \
  src 10.0.0.50
```

The `src` value affects locally generated traffic that uses that route.

> [!TIP]
> **Try it — see the source address follow the chosen interface**
>
> ```sh
> ip route get 10.0.0.9
> ip route get 192.168.70.9
> ```
>
> Expect something like:
>
> ```text
> 10.0.0.9 dev enp0s2 src 10.0.0.50 uid 1000
> 192.168.70.9 dev enp0s3 src 192.168.70.50 uid 1000
> ```
>
> Each lookup lands on a different interface and reports that interface's own address as `src`. No `via` appears because both destinations are on directly connected networks.

## Replacing an existing route

`ip route add` fails if an identical destination route already exists. Use `replace` to create or update in one step:

```bash
sudo ip route replace 172.16.0.0/16 via 10.0.0.1 dev eth1
```

This is handy when the next-hop gateway or outgoing interface needs to change. Changing a route can immediately interrupt active connections that were using it.

## Removing a static route

Remove a route by its destination:

```bash
sudo ip route del 172.16.0.0/16
```

A more specific deletion can name the gateway and interface:

```bash
sudo ip route del 172.16.0.0/16 via 10.0.0.1 dev eth1
```

Then re-display the table:

```bash
ip route show
```

## Testing the next-hop gateway

Before relying on a static route, confirm the next-hop gateway is reachable through the expected interface.

```bash
ping -c 3 -I eth1 10.0.0.1
```

`-I eth1` tells `ping` to use `eth1`. A failed ping does not always prove the gateway is down — firewalls can block ICMP (the protocol `ping` uses) — but it is a useful first check.

Show the neighbour table to see whether Linux has learned the gateway's MAC address:

```bash
ip neigh show dev eth1
```

Example:

```text
10.0.0.1 lladdr 52:54:00:12:34:56 REACHABLE
```

A `REACHABLE` entry confirms the gateway answers at Layer 2.

> [!TIP]
> **Try it — what an unreachable next hop looks like**
>
> No router exists on the playground's segments, so this is the failing case, on purpose:
>
> ```sh
> ping -c 2 -I enp0s2 10.0.0.1
> ip neigh show dev enp0s2
> ```
>
> Expect something like:
>
> ```text
> 2 packets transmitted, 0 received, 100% packet loss, time 1002ms
> 10.0.0.1  FAILED
> ```
>
> The interface is up and the route is valid, yet nothing answers at `10.0.0.1`. That gap — a correct route to a next hop that is not actually there — is exactly what this check catches. A real reachable gateway would show `REACHABLE` with a MAC address.

## Tracing the path to a destination

`traceroute` tries to show the Layer 3 hops between the local machine and a destination. Use numeric addresses to skip DNS lookups:

```bash
traceroute -n 172.16.100.5
```

Example output:

```text
traceroute to 172.16.100.5, 30 hops max
 1  10.0.0.1       0.412 ms  0.385 ms  0.401 ms
 2  172.16.0.1     1.204 ms  1.182 ms  1.195 ms
 3  172.16.100.5   1.845 ms  1.802 ms  1.821 ms
```

This suggests packets travel through the local gateway `10.0.0.1`, an intermediate router `172.16.0.1`, then the destination.

Some routers and firewalls do not send the replies `traceroute` relies on, so hops may show as `*`. A missing reply does not by itself mean forwarding has stopped. The `traceroute` package is not installed by default on every distribution.

> In this playground there is no router forwarding beyond the host, so `traceroute -n 172.16.100.5` just times out with `* * *` on every hop. A working trace needs at least one real forwarding router on the path, which the sandbox does not provide.

## Return paths and asymmetric routing

A working outbound route is only half of a conversation. The destination also needs a route back to the source address.

If the machine sends:

```text
10.0.0.50 → 172.16.100.5
```

then the destination network must know how to return traffic to `10.0.0.50`. If that return route is missing, requests arrive but replies never come back.

A reply can also return through a **different** interface than the request left by. This is **asymmetric routing**, and it can cause trouble for:

- Stateful firewalls.
- NAT gateways.
- Reverse-path filtering.
- Applications that expect a consistent path.
- Troubleshooting and packet captures.

Design multi-interface systems with both the outgoing and the return path in mind.

## Policy routing

The main routing table selects routes mostly by destination address. More advanced multi-interface setups sometimes need to decide by other things:

- The source IP address.
- The incoming interface.
- A firewall mark.
- A separate routing table.

Linux supports this through **policy routing**.

Show policy-routing rules:

```bash
ip rule show
```

Show all IPv4 routing tables:

```bash
ip route show table all
```

Policy routing is useful when a machine has multiple uplinks and traffic from each source network must leave through a specific gateway. Get comfortable with basic static routing before adding extra tables and rules.

> [!TIP]
> **Try it — look at the rule base before changing anything**
>
> ```sh
> ip rule show
> ```
>
> Expect something like:
>
> ```text
> 0:      from all lookup local
> 32766:  from all lookup main
> 32767:  from all lookup default
> ```
>
> These three rules are the default set every Linux host has: `local` first, then `main` (the table `ip route show` displays), then `default`. Policy routing works by inserting higher-priority rules — lower numbers — above `main`.

## Temporary and persistent routes

Routes created with `ip route` are runtime-only. They normally disappear when the machine restarts.

Persistent routes should be configured through the distribution's network-management system, such as:

- NetworkManager.
- Netplan.
- `systemd-networkd`.
- `ifupdown`.
- Distribution-specific network configuration files.

Do not configure the same interfaces and routes through more than one such system — routes can then appear, disappear, or change unexpectedly.

> [!TIP]
> **Try it — confirm added routes do not survive a reboot**
>
> This restarts the VM and drops your SSH session for a minute; reconnect with `astrona ssh static-routing-playground`.
>
> ```sh
> sudo reboot
> ```
>
> After reconnecting:
>
> ```sh
> ip route show
> ```
>
> The static routes and the extra default you added with `ip route` are gone; only connected routes and the management default remain. If the two lab interface addresses were set at runtime, re-add them with `ip addr add` before repeating the earlier checkpoints.

## A structured troubleshooting order

When a destination cannot be reached, it helps to check the network in order, narrowing down where the path breaks:

1. Is the interface enabled? — `ip link show`
2. Does it have the right IP address? — `ip addr show`
3. What does the routing table contain? — `ip route show`
4. Which route would Linux pick for this destination? — `ip route get 172.16.100.5`
5. Is the next-hop gateway known at Layer 2? — `ip neigh show`
6. Does the next-hop gateway respond? — `ping -c 3 -I eth1 10.0.0.1`
7. Where does a trace toward the destination stop? — `traceroute -n 172.16.100.5`
8. Does the remote network have a valid **return** route?

Walking these in order shows whether the problem is the interface, the local address, route selection, the gateway, an intermediate network, the destination, or the return path.
