# Test The Path

Astronaut, a lane on the star chart is only a plan. Before you trust it, check that the relay ship is really there, that the signal gets through, and that the reply can find its way home. In this part you test the next hop, trace a path, think about return paths, and learn a troubleshooting order you can use on any "I cannot reach it" problem.

## Testing the next-hop gateway

Before you rely on a static route, confirm that the next hop answers through the expected interface. Two commands do this: `ping` sends a real signal, and `ip neigh` shows whether the gateway answered at Layer 2.

### Ping through one interface

```bash
ping -c 3 -I eth1 10.0.0.1
```

`-I eth1` makes `ping` use that interface. A failed ping does not prove the gateway is down, because firewalls can block ICMP (Internet Control Message Protocol), the protocol `ping` uses. It is still a useful first check.

### The neighbour table

`ip neigh` shows the **neighbour table**: Linux's record of which MAC address belongs to which local IP address, built by ARP (Address Resolution Protocol).

```bash
ip neigh show dev eth1
```

```text
10.0.0.1 lladdr 52:54:00:12:34:56 REACHABLE
```

A `REACHABLE` entry with a MAC address (`lladdr`) means the gateway answered at Layer 2. `FAILED` or an empty result means it did not.

### See it in your playground

<!-- astrona:playground:renew -->

No router exists on the playground's segments, so this is the failing case, on purpose:

```sh
ping -c 2 -I enp0s2 10.0.0.1
ip neigh show dev enp0s2
```

Expect something like:

```text
2 packets transmitted, 0 received, 100% packet loss, time 1002ms
10.0.0.1  FAILED
```

The interface is up and the route is valid, yet nothing answers at `10.0.0.1`. That gap, a correct route to a next hop that is not there, is exactly what this check catches. A real gateway that answers would show `REACHABLE` with a MAC address.

## Tracing the path to a destination

`traceroute` tries to show each Layer 3 hop on the way to a destination: each relay ship the signal passes. `-n` skips name lookups.

### A working trace

```bash
traceroute -n 172.16.100.5
```

```text
traceroute to 172.16.100.5, 30 hops max
 1  10.0.0.1       0.412 ms  0.385 ms  0.401 ms
 2  172.16.0.1     1.204 ms  1.182 ms  1.195 ms
 3  172.16.100.5   1.845 ms  1.802 ms  1.821 ms
```

Some routers and firewalls do not send the replies `traceroute` relies on, so a hop can show as `*` even though forwarding did not stop there.

In this playground no router forwards beyond the host, so `traceroute -n 172.16.100.5` times out with `* * *` on every hop. A working trace needs at least one real router on the path, which the playground does not have.

## Return paths and asymmetric routing

A working route out is only half of a conversation. The destination network also needs a route back to your source address.

### Both directions

If the machine sends `10.0.0.50 → 172.16.100.5`, but that network has no route back to `10.0.0.50`, requests arrive and replies never come back.

A reply can also come back through a **different** interface than the request left by. This is **asymmetric routing**. It causes trouble for stateful firewalls, NAT (network address translation) gateways, reverse-path filtering and packet captures. Design machines with several interfaces with both directions in mind.

## A structured troubleshooting order

When a destination cannot be reached, check the path in order, so you narrow down where it breaks. Each step looks at one piece: the interface, the local address, route selection, the gateway, a network in between, the destination, or the return path.

### Eight checks

1. Is the interface up? `ip link show`
2. Is the IP address right? `ip addr show`
3. What is in the routing table? `ip route show`
4. Which route would Linux pick? `ip route get 172.16.100.5`
5. Is the next hop known at Layer 2? `ip neigh show`
6. Does the next hop answer? `ping -c 3 -I eth1 10.0.0.1`
7. Where does a trace stop? `traceroute -n 172.16.100.5`
8. Does the remote network have a working **return** route?

> [!TIP]
> Always run the checks in this order, top to bottom. Jumping straight to `traceroute` wastes time when the real problem is an interface that is down or a missing address.

## Common pitfalls

> [!WARNING]
> - **Reading a failed ping as a dead gateway.** Firewalls can block ICMP. Check `ip neigh` as well before you decide.
> - **Forgetting the return path.** A correct route out does nothing if the far network has no route back to your source address. Check both directions.
> - **Reading `* * *` in a trace as "forwarding stopped".** Some routers do not answer `traceroute` but still forward traffic.
