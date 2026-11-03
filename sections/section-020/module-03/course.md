# Multi-Interface Static Routing

Astronaut, every signal your ship sends needs a lane. The ship's **routing table** is its star chart: for each sector of space it says which antenna to use and which relay ship to hand the signal to. Linux reads that chart for every outgoing packet, at Layer 3, the level that moves packets between networks by IP address.

For each packet, Linux works out which route matches the destination, which interface carries it, whether the destination is directly reachable or needs a gateway, and which source address to use. This matters most on a ship with several antennas on different networks.

## Learning objectives

After this module you can:

- Read a routing table line and find the destination prefix, outgoing interface, gateway (if any), scope and source address.
- Explain longest-prefix matching and predict which of several overlapping routes Linux picks for a destination.
- Add, replace and remove a static route with `ip route`, and explain why the `via` gateway must be on-link.
- Use `ip route get` to see the interface, gateway and source address Linux would choose, without sending a packet.
- Explain what a route metric does when two routes share a prefix, and why a lower metric on its own is not failover.
- Work through an unreachable destination in order (interface, address, route, next hop, return path) with `ip link`, `ip addr`, `ip route`, `ip neigh` and `ping`.

## Before you start

Every mission starts with a pre-flight check. Make sure you have the basics this module expects, and know what is waiting in your playground.

### What you should already know

- **A shell and `sudo`.** You can open a terminal and run a command with `sudo`, which borrows the captain's authority.
- **IPv4 addresses with a prefix.** You have seen an address such as `10.0.0.50/24`. The first part refreshes what the prefix length means, and route, connected route, gateway, metric and longest-prefix matching are explained when they first come up.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. Open a terminal on it with `astrona ssh static-routing-playground`.

It has three addressed interfaces:

- **The management interface.** It carries your SSH (Secure Shell) session, your link to mission control, and it holds the low-metric default route. Leave it and its default route alone.
- **`10.0.0.50/24`** on the isolated `10.0.0.0/24` segment.
- **`192.168.70.50/24`** on the isolated `192.168.70.0/24` segment.

Find the interface names with `ip -brief -4 addr show`. No router sits on either lab segment, so every static route you add points at a next hop that does not answer. That is on purpose: `ip route get` still resolves the route, because it sends no packet, while `ping` and `traceroute` show the failing case. Every route you add with `ip route` is runtime only, and a reboot clears it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Read The Star Chart](./course-01-read-the-star-chart.md): prefixes, key terms, and the routing table your playground starts with.
2. [Draw A Static Route](./course-02-draw-a-static-route.md): adding a route, the default route, and longest-prefix matching.
3. [Metrics, Sources And Rules](./course-03-metrics-sources-and-rules.md): metrics, source addresses, replacing and removing routes, and policy routing.
4. [Test The Path](./course-04-test-the-path.md): checking the next hop, tracing a path, return paths, and a troubleshooting order.
5. [Make Routes Last](./course-05-make-routes-last.md): runtime against persistent routes, and your mission.
6. [Wrap-Up: Mission Debrief](./course-06-wrap-up.md): a recap, your missions, and cleaning up.

## Why this matters

A machine with more than one network is only useful if its traffic leaves by the right door. The exam asks you to add a route, prove which way Linux sends a packet, and make the route survive a reboot. The troubleshooting order in this module also works for almost every "I cannot reach it" problem you will meet.
