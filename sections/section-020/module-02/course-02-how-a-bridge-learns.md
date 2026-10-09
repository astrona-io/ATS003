# How A Bridge Learns

Astronaut, a docking hub that shouted every signal to every bay would be useless. A bridge is smarter: it learns which ship sits behind which port and sends each frame only where it needs to go. In this part you read that learned table, put the bridge's IP address in the right place, and see where DHCP fits.

## How a bridge learns: the forwarding database

A bridge builds its **forwarding database** (FDB) by watching the *source* MAC address of every frame it receives, and noting the port the frame came in on. This section shows the table and the four steps the bridge follows for each frame.

### The table

```text
MAC address          Bridge port
52:54:00:11:22:33    eth3
52:54:00:aa:bb:cc    vnet0
```

### What the bridge does with each frame

For each incoming frame the bridge:

1. learns the source MAC address and the incoming port;
2. looks up the destination MAC address in the forwarding database;
3. if it knows it, forwards the frame out of that one port;
4. if it does not, floods the frame out of every other eligible port.

Broadcast frames, such as ARP (Address Resolution Protocol) requests, are always flooded to the other ports. This is exactly how a physical Ethernet switch behaves.

### See it in your playground

<!-- astrona:playground:renew -->

You need `br0` with one spare interface attached and both up. If you do not have that, create it: `sudo ip link add name br0 type bridge`, then `sudo ip link set enp0s2 master br0`, and bring `br0` and `enp0s2` up.

Read the forwarding database:

```sh
bridge fdb show br br0
```

On this quiet segment with only one host, expect mostly `permanent` entries (the port's own MAC address and multicast groups) and few or no learned ones:

```text
52:54:00:aa:bb:cc dev enp0s2 master br0 permanent
33:33:00:00:00:01 dev enp0s2 self permanent
```

Learned entries, mapping a MAC address to a port, only appear once another host sends frames through the bridge, and nothing else is on this segment. The learning is real; there is just no traffic here to fill the table.

## Moving the IP address to the bridge

When an interface joins a bridge, its address should move to the bridge. This section shows the move on a real network, then lets you add an address to `br0` in your playground.

### The move

If the port already has an address, remove it from the port and add it to the bridge. Put any default route on the bridge too:

```bash
sudo ip addr del 192.168.1.50/24 dev eth3
sudo ip addr add 192.168.1.50/24 dev br0
sudo ip route add default via 192.168.1.1 dev br0
```

Moving an address can break connections that were using it straight away.

### See it in your playground

The spare interfaces face `192.168.60.0/24` and have no address to move, so this only adds one to `br0`:

```sh
sudo ip addr add 192.168.60.10/24 dev br0
ip addr show dev br0
```

Expect something like:

```text
4: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ...
    inet 192.168.60.10/24 scope global br0
       valid_lft forever preferred_lft forever
```

The address is on `br0`. `ip addr show dev enp0s2` shows the port still has none: the port carries frames at Layer 2, while the bridge is the Layer 3 interface the host routes through. Remove it with `sudo ip addr del 192.168.60.10/24 dev br0`.

## Using DHCP with a bridge

DHCP (Dynamic Host Configuration Protocol) is the harbour master who hands out call signs to arriving ships. When a bridged host uses DHCP, the DHCP client runs on the bridge, not on a port. You can picture it as `DHCP client → br0 → eth3`.

The exact configuration depends on the network-management system (NetworkManager, Netplan, `systemd-networkd`, `ifupdown` and others). Never run DHCP clients on both the bridge and a port at the same time.

This playground has no DHCP server on its isolated segment, so a DHCP client on `br0` would get no answer. The idea matters in practice; the mechanics need a server this playground does not have.

## Common pitfalls

> [!WARNING]
> - **Expecting `bridge fdb show` to be full on a quiet segment.** Learned entries need traffic from other hosts. On a segment with one host you see mostly `permanent` entries. That is normal, not a broken bridge.
> - **Running DHCP on a port and on the bridge.** Run the DHCP client on the bridge only.
> - **Leaving the old address on the port.** After you move the address to `br0`, check with `ip addr show dev <port>` that the port has none.
