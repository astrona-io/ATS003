# Read The Star Chart

Astronaut, before you draw a new lane on the star chart, you must be able to read the one you have. In this part you refresh how network prefixes work, learn the words of routing, and read the routing table your playground starts with, line by line.

## Reading network prefixes

Routes are written as a network address plus a **prefix length**, such as `10.0.0.0/24`. The prefix length is how much of the call sign names the sector and how much names the ship.

### Three examples

The number after the slash is how many leading bits are fixed:

- `10.0.0.0/24`: the first 24 bits are fixed; it covers `10.0.0.0` to `10.0.0.255`.
- `172.16.0.0/16`: the first 16 bits are fixed; it covers `172.16.0.0` to `172.16.255.255`.
- `0.0.0.0/0`: nothing is fixed; it matches every IPv4 address. This is the **default route**.

A larger prefix number means a smaller, more specific range. This one idea drives most of route selection.

## Key terms

These words come up in every part of this module. Keep the table close until they feel normal.

| Term | Meaning in this module |
|---|---|
| **Route** | One routing table entry: a destination prefix plus how to reach it (interface, and a gateway if needed). A lane on the star chart. |
| **Connected route** | A route Linux adds by itself for a network on one of its own interfaces. No gateway needed. |
| **Gateway / next hop** | A router on a directly connected network that passes packets on toward a network you cannot reach directly: the relay ship. |
| **Default route** | The `0.0.0.0/0` route, used when nothing more specific matches: the lane for "everywhere else". |
| **Metric** | A preference number on a route: the cost of a lane. Lower wins when two routes share a prefix. |
| **Neighbour table** | Linux's record of which MAC address belongs to which local IP address (built by ARP, the Address Resolution Protocol, for IPv4). |
| **Asymmetric routing** | Replies coming back by a different interface or path than the request left by. |
| **Policy routing** | Choosing a route by more than the destination, for example by source address or incoming interface. |

## The routing table and the `ip route` command

`ip route` is the whole toolset for this module. This section lists its verbs, then reads a sample table field by field.

### The verbs

- `ip route show` (or just `ip route`) prints the IPv4 table; `ip -6 route show` prints the IPv6 table.
- `ip route add`, `ip route replace` and `ip route del` change the table (they need `sudo`).
- `ip route get <addr>` asks which route Linux *would* use for one destination: asking the navigator which lane a signal would take. It is a lookup only; it sends no packet.

### Connected routes

When you give an interface an address, the kernel adds a **connected route** for that network by itself. It has no gateway, because the network is directly attached. Take a machine with:

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

That is a default route through `192.168.1.1`, two connected routes (`proto kernel scope link`: made by the kernel, directly reachable), and one static route to `172.16.0.0/16` added by hand.

### One line, field by field

Reading the connected line for `eth1`:

- `10.0.0.0/24`: the destination network;
- `dev eth1`: the outgoing interface;
- `proto kernel`: the kernel created it by itself;
- `scope link`: directly reachable, no gateway;
- `src 10.0.0.50`: the preferred source address for traffic that uses this route.

### See it in your playground

<!-- astrona:playground:renew -->

Look at the routing table your playground starts with:

```sh
ip route show
```

Expect something like:

```text
default via 10.10.0.1 dev enp0s1 proto dhcp src 10.10.0.20 metric 100
10.0.0.0/24 dev enp0s2 proto kernel scope link src 10.0.0.50
10.10.0.0/24 dev enp0s1 proto kernel scope link src 10.10.0.20 metric 100
192.168.70.0/24 dev enp0s3 proto kernel scope link src 192.168.70.50
```

The three `proto kernel scope link` lines are connected routes, one per addressed interface, added by the kernel. The `default` line belongs to the management interface. Interface names and the management network vary; the two lab networks are `10.0.0.0/24` and `192.168.70.0/24`.

## Common pitfalls

> [!WARNING]
> - **Reading a bigger prefix number as a bigger network.** `/24` is smaller and more specific than `/16`. `/0` matches everything.
> - **Looking for a gateway on a connected route.** `scope link` routes have no `via`: the network is directly attached.
> - **Changing the management default route.** It carries your SSH session. Read it, but leave it alone.
