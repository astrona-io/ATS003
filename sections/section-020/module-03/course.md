# Multi-Interface Static Routing

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-020/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-03/playground
> astrona destroy static-routing-playground
> ```

A Linux machine uses its **routing table** to decide where to send Layer 3 packets. **Layer 3** moves packets between networks using IP addresses; a **route** is one table entry that says "traffic for this destination goes out that way."

For every outgoing packet Linux works out which route matches the destination, which interface carries the packet, whether the destination is directly reachable or must go through a gateway, and which source address to use. This matters most on a machine with several interfaces on different networks.

## Learning objectives

After this module you can:

- Read a routing-table line and identify the destination prefix, outgoing interface, gateway (if any), scope, and source address.
- Explain longest-prefix matching and predict which of several overlapping routes Linux picks for a given destination.
- Add, replace, and remove a static route with `ip route`, and explain why the `via` gateway must be on-link.
- Use `ip route get` to see the interface, gateway, and source address Linux would choose for a destination, without sending a packet.
- Explain what a route metric does when two routes share a prefix, and why a lower metric on its own is not failover.
- Work an unreachable destination in order — interface, address, route, next hop, return path — using `ip link`, `ip addr`, `ip route`, `ip neigh`, and `ping`.

## Before you start

This module assumes you can open a shell, run commands with `sudo`, and have seen a dotted IPv4 address with a prefix such as `10.0.0.50/24`. Route, connected route, gateway / next hop, metric, and longest-prefix matching are defined as they come up, and the "Reading network prefixes" section below refreshes prefix length first. Familiarity with `ip addr` and `ip link` from the interfaces module helps but is not assumed.

Open a shell on the playground VM with `astrona ssh astro-static-routing-playground`. It has three addressed interfaces: the management NIC that carries your SSH session — it holds the low-metric default route, so leave it alone — and two lab NICs on `10.0.0.0/24` and `192.168.70.0/24`. No router sits on either lab segment, so every static route you add points at a next hop that does not answer. That is deliberate: `ip route get` still resolves the route (it sends no packet), while `ping` and `traceroute` are the failing case on purpose. Every route added with `ip route` is runtime-only and is cleared by the reboot checkpoint.

## Reading network prefixes

Routes are written as a network address plus a **prefix length**, such as `10.0.0.0/24`. The number after the slash is how many leading bits are fixed:

- `10.0.0.0/24` — first 24 bits fixed; covers `10.0.0.0`–`10.0.0.255`.
- `172.16.0.0/16` — first 16 bits fixed; covers `172.16.0.0`–`172.16.255.255`.
- `0.0.0.0/0` — nothing fixed; matches every IPv4 address. This is the **default route**.

A larger prefix number means a smaller, more specific range. This idea drives most of route selection.

## Key terms

| Term | Meaning in this module |
|---|---|
| **Route** | One routing-table entry: a destination prefix plus how to reach it (interface, and a gateway if needed). |
| **Connected route** | A route Linux adds automatically for a network on one of its own interfaces. No gateway needed. |
| **Gateway / next hop** | A router on a directly connected network that forwards packets toward a network you cannot reach directly. |
| **Default route** | The `0.0.0.0/0` route, used when nothing more specific matches. |
| **Metric** | A preference number on a route. Lower is preferred when two routes share a prefix. |
| **Neighbour table** | Linux's record of which MAC address belongs to which local IP (built by ARP for IPv4). |
| **Asymmetric routing** | Replies returning by a different interface or path than the request left by. |
| **Policy routing** | Choosing a route by more than the destination — for example by source address or incoming interface. |

## The routing table and the `ip route` command

`ip route` is the whole toolset for this module. Its verbs:

- `ip route show` (or just `ip route`) — print the IPv4 table; `ip -6 route show` for IPv6.
- `ip route add` / `ip route replace` / `ip route del` — change the table (needs `sudo`).
- `ip route get <addr>` — ask which route Linux *would* use for one destination. A lookup only; it sends no packet.

When you give an interface an address, Linux automatically adds a **connected route** for that network — no gateway, because the network is directly attached. Consider a machine with:

```text
eth0: 192.168.1.50/24
eth1: 10.0.0.50/24
```

Its table might read:

```text
default via 192.168.1.1 dev eth0
10.0.0.0/24 dev eth1 proto kernel scope link src 10.0.0.50
172.16.0.0/16 via 10.0.0.1 dev eth1
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.50
```

That is a default route through `192.168.1.1`, two connected routes (`proto kernel scope link` — kernel-created, directly reachable), and one hand-added static route to `172.16.0.0/16`. Reading the connected line field by field:

- `10.0.0.0/24` — destination network;
- `dev eth1` — outgoing interface;
- `proto kernel` — Linux created it automatically;
- `scope link` — directly reachable, no gateway;
- `src 10.0.0.50` — preferred source address for traffic using this route.

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

## Static routes

A **static route** is one you configure by hand to reach a network that is not directly connected:

```bash
sudo ip route add 172.16.0.0/16 via 10.0.0.1 dev eth1
```

Read as: to reach an address in `172.16.0.0/16`, send the packet to gateway `10.0.0.1` through `eth1`. The parts are the destination network (`172.16.0.0/16`), the next-hop router (`via 10.0.0.1`), and the outgoing interface (`dev eth1`).

The gateway must be **on-link** — reachable on a network directly connected to the chosen interface. Here `10.0.0.1` has to be inside `eth1`'s `10.0.0.0/24`. A `via` address that is not on-link is rejected with `Error: Nexthop has invalid gateway`.

`ip route get` resolves a route without sending anything, so it works even when the gateway has nobody home:

```bash
ip route get 172.16.50.1
```

reports the interface, gateway, and source address Linux would use.

> [!TIP]
> **Try it — add a static route and ask Linux to resolve it**
>
> Use the interface on the `10.0.0.0/24` segment (the examples call it `enp0s2`). `10.0.0.1` is on-link there, so the add succeeds even though no router sits at that address in the playground.
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
> The route is in the table, and `ip route get` reports it would leave via `enp0s2` toward `10.0.0.1` using source `10.0.0.50` — a lookup only, which is why it works with a gateway nothing answers.

## The default route

The default route is used when no more specific route matches. `default` stands for `0.0.0.0/0`, which matches any IPv4 destination — but a more specific route always wins:

```text
default via 192.168.1.1 dev eth0
172.16.0.0/16 via 10.0.0.1 dev eth1
```

- Traffic for `192.168.1.20` → the connected `192.168.1.0/24` route.
- Traffic for `172.16.100.5` → the static `172.16.0.0/16` route.
- Traffic for `8.8.8.8` → the default route.

A host normally has one default route. Linux can hold more, separated by metric or by policy routing.

## Longest-prefix matching

When several routes match a destination, Linux picks the one with the **longest matching prefix** — the most specific. Given:

```text
default via 192.168.1.1 dev eth0
172.16.0.0/16 via 10.0.0.1 dev eth1
172.16.100.0/24 via 192.168.1.254 dev eth0
```

for `172.16.100.5` both the `/16` and the `/24` match; the `/24` is more specific, so Linux uses `172.16.100.0/24 via 192.168.1.254 dev eth0`. The default route's `/0` is the shortest possible prefix, so it loses to everything else.

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
> `172.16.100.5` matches both routes and takes the `/24` out `enp0s3`; `172.16.5.5` matches only the `/16` and takes that out `enp0s2`. Same destination family, different interface, decided purely by prefix length.

## Route metrics

When several routes have the **same** destination prefix, the **metric** decides which is preferred — lower is better:

```text
default via 192.168.1.1 dev eth0 metric 100
default via 10.0.0.1 dev eth1 metric 200
```

The `eth0` route wins; the `eth1` route is a standby that may be used if the first is removed. A lower metric does **not** on its own give failover — Linux still has to notice the preferred route or its interface is gone before it moves.

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

## Source-address selection

A multi-interface host has several addresses, and Linux picks a source address per outgoing packet. By default it uses the address on the interface the route selected:

```text
eth0: 192.168.1.50/24   →  traffic out eth0 uses 192.168.1.50
eth1: 10.0.0.50/24      →  traffic out eth1 uses 10.0.0.50
```

A preferred source can be pinned on a static route with `src`, which affects locally generated traffic using that route:

```bash
sudo ip route add 172.16.0.0/16 via 10.0.0.1 dev eth1 src 10.0.0.50
```

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

## Replacing and removing routes

`ip route add` fails if an identical destination route already exists. `ip route replace` creates or updates in one step — handy when the next hop or interface changes:

```bash
sudo ip route replace 172.16.0.0/16 via 10.0.0.1 dev eth1
```

Remove a route by destination, optionally narrowing by gateway and interface:

```bash
sudo ip route del 172.16.0.0/16
sudo ip route del 172.16.0.0/16 via 10.0.0.1 dev eth1
```

Changing or deleting a route can immediately interrupt connections that were using it.

## Testing the next-hop gateway

Before relying on a static route, confirm the next hop actually answers through the expected interface.

```bash
ping -c 3 -I eth1 10.0.0.1
```

`-I eth1` forces `ping` to use that interface. A failed ping is not proof the gateway is down — firewalls can block ICMP, the protocol `ping` uses — but it is a useful first check.

`ip neigh` shows the **neighbour table**: Linux's cache of which MAC address belongs to which local IP, built by ARP.

```bash
ip neigh show dev eth1
```

```text
10.0.0.1 lladdr 52:54:00:12:34:56 REACHABLE
```

A `REACHABLE` entry with a MAC (`lladdr`) means the gateway answered at Layer 2. `FAILED` or an empty result means it did not.

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
> The interface is up and the route is valid, yet nothing answers at `10.0.0.1`. That gap — a correct route to a next hop that is not there — is exactly what this check catches. A real reachable gateway would show `REACHABLE` with a MAC address.

## Tracing the path to a destination

`traceroute` tries to show the Layer 3 hops to a destination. `-n` skips DNS lookups:

```bash
traceroute -n 172.16.100.5
```

```text
traceroute to 172.16.100.5, 30 hops max
 1  10.0.0.1       0.412 ms  0.385 ms  0.401 ms
 2  172.16.0.1     1.204 ms  1.182 ms  1.195 ms
 3  172.16.100.5   1.845 ms  1.802 ms  1.821 ms
```

Some routers and firewalls withhold the replies `traceroute` relies on, so hops can show as `*` without meaning forwarding stopped.

> In this playground no router forwards beyond the host, so `traceroute -n 172.16.100.5` times out with `* * *` on every hop. A working trace needs at least one real forwarding router on the path, which the sandbox does not provide.

## Return paths and asymmetric routing

A working outbound route is only half of a conversation. The destination network also needs a route back to your source address. If the machine sends `10.0.0.50 → 172.16.100.5` but that network has no return route to `10.0.0.50`, requests arrive and replies never come back.

A reply can also return through a **different** interface than the request left by — **asymmetric routing**. It causes trouble for stateful firewalls, NAT gateways, reverse-path filtering, and packet captures. Design multi-interface systems with both directions in mind.

## Policy routing

The main table selects routes mostly by destination. Advanced multi-uplink setups sometimes need to decide by source address, incoming interface, a firewall mark, or a separate table. Linux does this with **policy routing**, driven by a rule base:

```bash
ip rule show               # the rules
ip route show table all    # every routing table, not just main
```

`ip rule` lists the ordered rules that pick *which table* a lookup uses. Policy routing works by inserting higher-priority rules (lower numbers) above `main`.

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
> These three are the default set every Linux host has: `local` first, then `main` (the table `ip route show` displays), then `default`. Get comfortable with plain static routing before adding extra tables and rules.

## Runtime versus persistent routes

Routes created with `ip route` are runtime-only — normally gone after a restart. Persistent routes are configured through the distribution's network-management system (NetworkManager, Netplan, `systemd-networkd`, `ifupdown`, …). Do not configure the same routes through more than one such system — they can then appear, disappear, or change unexpectedly.

> [!TIP]
> **Try it — confirm added routes do not survive a reboot**
>
> This restarts the VM and drops your SSH session for about a minute; reconnect with `astrona ssh astro-static-routing-playground`.
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

When a destination cannot be reached, check the path in order so you narrow down where it breaks:

1. Interface enabled? — `ip link show`
2. Right IP address? — `ip addr show`
3. What is in the routing table? — `ip route show`
4. Which route would Linux pick? — `ip route get 172.16.100.5`
5. Is the next hop known at Layer 2? — `ip neigh show`
6. Does the next hop respond? — `ping -c 3 -I eth1 10.0.0.1`
7. Where does a trace stop? — `traceroute -n 172.16.100.5`
8. Does the remote network have a valid **return** route?

Each step isolates one part: interface, local address, route selection, gateway, an intermediate network, the destination, or the return path.

> [!WARNING]
> **Common pitfalls**
>
> - **A `via` gateway that is not on-link.** `ip route add … via <addr>` needs `<addr>` on a network directly attached to `dev`. Otherwise: `Error: Nexthop has invalid gateway`. Add or confirm the connected route first.
> - **Treating a low metric as failover.** Metric only orders routes with the same prefix. Linux still needs to detect the preferred route or interface is gone before it switches. Real failover needs link monitoring or a daemon.
> - **`ip route get` succeeding and reading it as "reachable".** `ip route get` is a table lookup, not a send. It resolves fine through a next hop that answers nothing. Confirm reachability with `ping` / `ip neigh`.
> - **Forgetting the return path.** A correct outbound route does nothing if the far network has no route back to your source address. Check both directions.
> - **`ip route del` not matching.** A route added with a specific `via`/`dev`/`metric` may need the same qualifiers to delete. If `del <prefix>` fails, match the line as `ip route show` prints it.
