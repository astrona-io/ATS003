# Metrics, Sources And Rules

Astronaut, sometimes two lanes lead to the same sector, and sometimes the ship has more than one call sign to sign a signal with. In this part you learn how Linux chooses between equal lanes with a **metric**, how it picks a source address, how to change or remove a route, and where policy routing sits.

## Route metrics

When several routes have the **same** destination prefix, the metric decides which one is preferred. It is the cost of a lane: lower is better.

### Two default routes

```text
default via 192.168.1.1 dev eth0 metric 100
default via 10.0.0.1 dev eth1 metric 200
```

The `eth0` route wins. The `eth1` route is a standby that may be used if the first is removed. A lower metric does **not** give failover on its own: Linux still has to notice that the preferred route or its interface is gone before it moves.

### See it in your playground

<!-- astrona:playground:renew -->

Do not touch the existing low-metric default on the management interface: that route carries your SSH session. Only add, and later remove, the extra one below:

```sh
sudo ip route add default via 10.0.0.1 dev enp0s2 metric 500
ip route show default
ip route get 8.8.8.8
```

Expect something like:

```text
default via 10.10.0.1 dev enp0s1 proto dhcp src 10.10.0.20 metric 100
default via 10.0.0.1 dev enp0s2 metric 500
...
8.8.8.8 via 10.10.0.1 dev enp0s1 src 10.10.0.20 uid 1000
```

Both default routes sit in the table, ordered by metric, and the lower-metric one is still chosen. Remove the one you added with `sudo ip route del default via 10.0.0.1 dev enp0s2 metric 500`.

## Source-address selection

A ship with several antennas has several call signs, and Linux picks a source address for each outgoing packet. This section shows the default choice and how to pin one.

### The default choice

By default the kernel uses the address on the interface the route selected:

```text
eth0: 192.168.1.50/24   →  traffic out eth0 uses 192.168.1.50
eth1: 10.0.0.50/24      →  traffic out eth1 uses 10.0.0.50
```

### Pinning a source

You can pin a preferred source on a static route with `src`. It affects traffic the machine itself sends through that route:

```bash
sudo ip route add 172.16.0.0/16 via 10.0.0.1 dev eth1 src 10.0.0.50
```

### See it in your playground

Ask for two destinations on different lab networks:

```sh
ip route get 10.0.0.9
ip route get 192.168.70.9
```

Expect something like:

```text
10.0.0.9 dev enp0s2 src 10.0.0.50 uid 1000
192.168.70.9 dev enp0s3 src 192.168.70.50 uid 1000
```

Each lookup lands on a different interface and reports that interface's own address as `src`. No `via` appears, because both destinations are on directly connected networks.

## Replacing and removing routes

Routes change: a gateway moves, an interface is renamed, a lane closes. `ip route` has a verb for each case.

### Replace

`ip route add` fails if the same destination route already exists. `ip route replace` creates or updates in one step, which is handy when the next hop or interface changes:

```bash
sudo ip route replace 172.16.0.0/16 via 10.0.0.1 dev eth1
```

### Remove

Remove a route by destination, and narrow it by gateway and interface if needed:

```bash
sudo ip route del 172.16.0.0/16
sudo ip route del 172.16.0.0/16 via 10.0.0.1 dev eth1
```

Changing or deleting a route can cut off connections that were using it straight away.

## Policy routing

The main table chooses routes mostly by destination. Some setups with several uplinks need to decide by source address, incoming interface, a firewall mark, or a separate table. Linux does this with **policy routing**, driven by a list of rules.

### The rules and the tables

```bash
ip rule show               # the rules
ip route show table all    # every routing table, not just main
```

`ip rule` lists the ordered rules that pick *which table* a lookup uses. Policy routing works by adding rules with a higher priority (a lower number) above `main`.

### See it in your playground

Look at the rule list before you change anything:

```sh
ip rule show
```

Expect something like:

```text
0:      from all lookup local
32766:  from all lookup main
32767:  from all lookup default
```

These three are the default set every Linux host has: `local` first, then `main` (the table `ip route show` displays), then `default`. Get comfortable with plain static routing before you add extra tables and rules.

## Common pitfalls

> [!WARNING]
> - **Treating a low metric as failover.** Metric only orders routes with the same prefix. Linux still has to notice that the preferred route or interface is gone before it switches. Real failover needs link monitoring or a routing service.
> - **`ip route del` not matching.** A route added with a specific `via`, `dev` or `metric` may need the same details to delete. If `del <prefix>` fails, match the line exactly as `ip route show` prints it.
> - **Using `add` to change a route.** `add` fails when the route exists. Use `replace`.
