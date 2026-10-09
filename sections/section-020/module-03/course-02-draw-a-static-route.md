# Draw A Static Route

Astronaut, now you draw a lane on the star chart by hand. A **static route** tells Linux how to reach a network it is not directly attached to. In this part you add one, ask the navigator which lane a signal would take, and see why the most specific lane always wins, even over the default route.

## Static routes

A static route names a destination network, the relay ship to hand packets to, and the antenna to use. This section reads one route, explains the on-link rule, and then lets you add one.

### One route, three parts

```bash
sudo ip route add 172.16.0.0/16 via 10.0.0.1 dev eth1
```

Read it as: to reach an address in `172.16.0.0/16`, send the packet to gateway `10.0.0.1` through `eth1`. The parts are the destination network (`172.16.0.0/16`), the next-hop router (`via 10.0.0.1`) and the outgoing interface (`dev eth1`).

### The gateway must be on-link

The gateway must be **on-link**: reachable on a network directly connected to the chosen interface. Here `10.0.0.1` has to be inside `eth1`'s `10.0.0.0/24`. A `via` address that is not on-link is rejected with `Error: Nexthop has invalid gateway`.

### Ask the navigator

`ip route get` resolves a route without sending anything, so it works even when nobody is home at the gateway:

```bash
ip route get 172.16.50.1
```

It reports the interface, gateway and source address Linux would use.

### See it in your playground

<!-- astrona:playground:renew -->

Use the interface on the `10.0.0.0/24` segment (the examples call it `enp0s2`). `10.0.0.1` is on-link there, so the add works even though no router sits at that address in the playground:

```sh
sudo ip route add 172.16.0.0/16 via 10.0.0.1 dev enp0s2
ip route show
ip route get 172.16.50.1
```

Expect something like:

```text
172.16.0.0/16 via 10.0.0.1 dev enp0s2
...
172.16.50.1 via 10.0.0.1 dev enp0s2 src 10.0.0.50 uid 1000
    cache
```

The route is in the table, and `ip route get` reports that the packet would leave by `enp0s2` toward `10.0.0.1`, with source `10.0.0.50`. It is a lookup only, which is why it works with a gateway that answers nothing.

## The default route

The default route is the lane for "everywhere else". `default` stands for `0.0.0.0/0`, which matches any IPv4 destination, but a more specific route always wins over it.

### Which route each destination takes

```text
default via 192.168.1.1 dev eth0
172.16.0.0/16 via 10.0.0.1 dev eth1
```

- Traffic for `192.168.1.20` takes the connected `192.168.1.0/24` route.
- Traffic for `172.16.100.5` takes the static `172.16.0.0/16` route.
- Traffic for `8.8.8.8` takes the default route.

A host normally has one default route. Linux can hold more, separated by metric or by policy routing.

## Longest-prefix matching

When several routes match a destination, Linux picks the one with the **longest matching prefix**: the most specific one. This section shows the rule on paper, then in your playground.

### The rule on paper

Given:

```text
default via 192.168.1.1 dev eth0
172.16.0.0/16 via 10.0.0.1 dev eth1
172.16.100.0/24 via 192.168.1.254 dev eth0
```

For `172.16.100.5`, both the `/16` and the `/24` match. The `/24` is more specific, so Linux uses `172.16.100.0/24 via 192.168.1.254 dev eth0`. The default route's `/0` is the shortest possible prefix, so it loses to everything else.

### See it in your playground

Keep the `172.16.0.0/16` route you just added. Add a `/24` inside it that points the other way, then compare two lookups:

```sh
sudo ip route add 172.16.100.0/24 via 192.168.70.1 dev enp0s3
ip route get 172.16.100.5
ip route get 172.16.5.5
```

Expect something like:

```text
172.16.100.5 via 192.168.70.1 dev enp0s3 src 192.168.70.50 uid 1000
172.16.5.5 via 10.0.0.1 dev enp0s2 src 10.0.0.50 uid 1000
```

`172.16.100.5` matches both routes and takes the `/24` out of `enp0s3`. `172.16.5.5` matches only the `/16` and takes that one out of `enp0s2`. Same family of destinations, different interface, decided only by prefix length.

> [!TIP]
> Before you change a route, ask `ip route get <address>` first. It tells you which lane Linux uses today, so you can predict exactly what your change will move.

## Common pitfalls

> [!WARNING]
> - **A `via` gateway that is not on-link.** `ip route add … via <addr>` needs `<addr>` on a network directly attached to `dev`. Otherwise you get `Error: Nexthop has invalid gateway`. Add or confirm the connected route first.
> - **Reading a successful `ip route get` as "reachable".** `ip route get` is a table lookup, not a send. It resolves fine through a next hop that answers nothing.
> - **Expecting the default route to win.** Any more specific route beats `0.0.0.0/0`.
