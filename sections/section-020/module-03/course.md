# Multi-Interface Static Routing

A Linux machine uses its routing table to decide where to send Layer 3 network packets.

For every outgoing packet, Linux must determine:

- Which route matches the destination.
- Which network interface should carry the packet.
- Whether the destination is directly reachable.
- Whether the packet must be sent through a gateway.
- Which source IP address should be used.

This becomes especially important when a machine has multiple network interfaces connected to different networks.

## A machine with multiple interfaces

Consider a Linux machine with two interfaces:

```text
eth0: 192.168.1.50/24
eth1: 10.0.0.50/24
```

The interfaces connect the machine to two different networks:

```text
192.168.1.0/24 ─── eth0 ─── Linux host ─── eth1 ─── 10.0.0.0/24
```

Linux normally creates a directly connected route when an IP address is assigned to an interface.

The routing table may contain:

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

## Understanding a connected route

Consider this route:

```text
10.0.0.0/24 dev eth1 proto kernel scope link src 10.0.0.50
```

Its fields mean:

- `10.0.0.0/24` is the destination network.
- `dev eth1` identifies the outgoing interface.
- `proto kernel` means Linux created the route automatically.
- `scope link` means the network is directly reachable.
- `src 10.0.0.50` is the preferred source address.

A gateway is not required because the destination network is directly connected to `eth1`.

## Understanding a static route

A static route is manually configured to tell Linux how to reach a network that is not directly connected.

Example:

```bash
sudo ip route add 172.16.0.0/16 via 10.0.0.1 dev eth1
```

This command tells Linux:

> To reach an address in `172.16.0.0/16`, send the packet to gateway `10.0.0.1` through `eth1`.

The components are:

- `172.16.0.0/16`: The destination network.
- `via 10.0.0.1`: The next-hop router.
- `dev eth1`: The outgoing interface.

The gateway must normally be reachable through the selected interface. In this example, `10.0.0.1` must be reachable from the local `10.0.0.0/24` network on `eth1`.

A second example routes traffic through `eth0`:

```bash
sudo ip route add 10.50.0.0/16 via 192.168.1.254 dev eth0
```

This tells Linux to send traffic for `10.50.0.0/16` to router `192.168.1.254` through `eth0`.

## Understanding the default route

A default route is used when no more specific route matches the destination.

Example:

```text
default via 192.168.1.1 dev eth0
```

The word `default` represents:

```text
0.0.0.0/0
```

This route can match any IPv4 destination, but a more specific route is preferred.

For example:

- Traffic for `192.168.1.20` uses the directly connected `192.168.1.0/24` route.
- Traffic for `172.16.100.5` uses the static `172.16.0.0/16` route.
- Traffic for `8.8.8.8` uses the default route.

A host normally has one default route, but Linux can support multiple default routes using route metrics or policy routing.

## Longest-prefix matching

Linux normally selects the route with the longest matching network prefix.

Consider these routes:

```text
default via 192.168.1.1 dev eth0
172.16.0.0/16 via 10.0.0.1 dev eth1
172.16.100.0/24 via 192.168.1.254 dev eth0
```

For the destination `172.16.100.5`, both of these routes match:

```text
172.16.0.0/16
172.16.100.0/24
```

The `/24` route is more specific than the `/16` route, so Linux selects:

```text
172.16.100.0/24 via 192.168.1.254 dev eth0
```

This is called **longest-prefix matching**.

The default route has the shortest possible prefix, `/0`, so it is only selected when no more specific route is available.

## Route metrics

When multiple routes have the same destination prefix, a metric can indicate which route is preferred.

A lower metric is normally preferred.

Example:

```text
default via 192.168.1.1 dev eth0 metric 100
default via 10.0.0.1 dev eth1 metric 200
```

In this example:

- The route through `eth0` is preferred.
- The route through `eth1` has a higher metric.
- The second route may be used if the preferred route is removed.

A route can be created with a metric:

```bash
sudo ip route add default via 10.0.0.1 dev eth1 metric 200
```

A lower metric does not automatically provide complete failover. Linux must detect that the preferred route or interface is unavailable before selecting another route.

## Inspecting the route to a destination

Use `ip route get` to ask Linux which route it would select for a particular destination:

```bash
ip route get 8.8.8.8
```

Example output:

```text
8.8.8.8 via 192.168.1.1 dev eth0 src 192.168.1.50 uid 1000
```

This output indicates:

- `8.8.8.8` is the destination.
- `192.168.1.1` is the selected gateway.
- `eth0` is the selected outgoing interface.
- `192.168.1.50` is the selected source address.

Inspect a destination reached through a static route:

```bash
ip route get 172.16.100.5
```

Example:

```text
172.16.100.5 via 10.0.0.1 dev eth1 src 10.0.0.50
```

The `ip route get` command performs a route lookup. It does not send a packet to the destination.

## Selecting a source address

A multi-interface host has multiple IP addresses. Linux must select an appropriate source address for each outgoing packet.

For example:

```text
eth0: 192.168.1.50/24
eth1: 10.0.0.50/24
```

Traffic leaving through `eth0` will normally use:

```text
192.168.1.50
```

Traffic leaving through `eth1` will normally use:

```text
10.0.0.50
```

A preferred source address can be included in a static route:

```bash
sudo ip route add 172.16.0.0/16 \
  via 10.0.0.1 \
  dev eth1 \
  src 10.0.0.50
```

The `src` value influences locally generated traffic using that route.

## Replacing an existing route

The `ip route add` command fails if an identical destination route already exists.

Use `replace` when a route should be created or updated:

```bash
sudo ip route replace 172.16.0.0/16 via 10.0.0.1 dev eth1
```

This is useful when the current next-hop gateway or outgoing interface needs to change.

Changing a route can immediately interrupt active network connections.

## Removing a static route

Remove a static route by specifying its destination:

```bash
sudo ip route del 172.16.0.0/16
```

A more specific deletion can include the gateway and interface:

```bash
sudo ip route del 172.16.0.0/16 via 10.0.0.1 dev eth1
```

Display the routing table afterward:

```bash
ip route show
```

## Testing the next-hop gateway

Before relying on a static route, confirm that the next-hop gateway is reachable through the expected interface.

Example:

```bash
ping -c 3 -I eth1 10.0.0.1
```

The `-I eth1` option tells `ping` to use `eth1`.

A failed ping does not always prove the gateway is unavailable because firewalls can block ICMP traffic. However, it can provide a useful initial connectivity check.

Display the neighbour table to determine whether Linux has learned the gateway's MAC address:

```bash
ip neigh show dev eth1
```

Example:

```text
10.0.0.1 lladdr 52:54:00:12:34:56 REACHABLE
```

A reachable neighbour entry confirms that the gateway is accessible at Layer 2.

## Tracing the path to a destination

The `traceroute` command attempts to show the intermediate Layer 3 hops between the local machine and a destination.

Use numeric addresses to avoid DNS lookups:

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

This output suggests that packets travel through:

1. The local gateway at `10.0.0.1`.
2. An intermediate router at `172.16.0.1`.
3. The destination at `172.16.100.5`.

Some routers and firewalls do not return the responses used by `traceroute`. Missing hops may appear as:

```text
*
```

A missing response does not necessarily mean that packet forwarding has stopped.

The `traceroute` package may not be installed by default on every Linux distribution.

## Return paths and asymmetric routing

A working outbound route is only one part of successful communication. The destination also needs a route back to the source address.

For example, the local machine may send traffic like this:

```text
10.0.0.50 → 172.16.100.5
```

The destination network must know how to return traffic to:

```text
10.0.0.50
```

If the return route is missing, outgoing packets may reach the destination while responses never return.

A response can also return through a different interface from the one used by the outgoing packet. This is called **asymmetric routing**.

Asymmetric routing can cause problems with:

- Stateful firewalls.
- NAT gateways.
- Reverse-path filtering.
- Applications that expect a consistent network path.
- Troubleshooting and packet captures.

Multi-interface systems should therefore be designed with both outgoing and return paths in mind.

## Policy routing

The main routing table primarily selects routes according to the destination address.

More advanced multi-interface systems may need routing decisions based on additional information, such as:

- The source IP address.
- The incoming interface.
- A firewall mark.
- A separate routing table.

Linux supports this through **policy routing**.

Display policy-routing rules:

```bash
ip rule show
```

Display all IPv4 routing tables:

```bash
ip route show table all
```

Policy routing is useful when a machine has multiple uplinks and traffic from each source network must leave through a specific gateway.

Basic static routing should be understood before introducing additional routing tables and policy rules.

## Temporary and persistent routes

Routes created with the `ip route` command are runtime-only configurations. They normally disappear after the machine restarts.

Persistent routes should be configured using the network-management system provided by the Linux distribution, such as:

- NetworkManager.
- Netplan.
- `systemd-networkd`.
- `ifupdown`.
- Distribution-specific network configuration files.

Do not configure the same interfaces and routes through multiple network-management systems. Conflicting configurations can cause routes to appear, disappear, or change unexpectedly.

## A structured troubleshooting process

When a destination cannot be reached, inspect the network in this order:

1. Confirm that the required interface is enabled:

   ```bash
   ip link show
   ```

2. Confirm that the interface has the correct IP address:

   ```bash
   ip addr show
   ```

3. Inspect the routing table:

   ```bash
   ip route show
   ```

4. Ask Linux which route it would select:

   ```bash
   ip route get 172.16.100.5
   ```

5. Verify that the next-hop gateway is locally reachable:

   ```bash
   ip neigh show
   ```

6. Test the next-hop gateway:

   ```bash
   ping -c 3 -I eth1 10.0.0.1
   ```

7. Trace the path toward the destination:

   ```bash
   traceroute -n 172.16.100.5
   ```

8. Confirm that the remote network has a valid return route.

This process helps identify whether the problem is related to the interface, local address, route selection, gateway, intermediate network, destination, or return path.