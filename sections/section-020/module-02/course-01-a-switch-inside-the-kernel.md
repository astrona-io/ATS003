# A Switch Inside The Kernel

Astronaut, in this part you build a docking hub. A software bridge is a virtual Layer 2 switch inside the kernel. You first see where it sits and where the IP address goes, then meet the two tools that build and inspect it, and finally create `br0` and plug one antenna into it.

## What a bridge connects

A bridge joins interfaces so frames pass between them, just like a physical switch. Here is the classic picture:

```text
                     Linux host

eth3 ──────────────── br0 ──────────────── vnet0
Physical interface   Software bridge       Virtual interface
```

`br0` lets a virtual machine on `vnet0` reach the physical network through `eth3`. The interfaces attached to a bridge are its **bridge ports** (or member interfaces).

## Key terms

These words come up in every part of this module. Keep the table close until they feel normal.

| Term | Meaning in this module |
|---|---|
| **Ethernet frame** | The unit of data on a local segment; it carries a source and a destination MAC address. |
| **MAC address** | The hardware address of an interface, such as `52:54:00:11:22:33`, used for local delivery: the serial number on the antenna. |
| **Layer 2** | Local delivery on one segment, by MAC address. A bridge works here. |
| **Layer 3** | Delivery between networks, by IP address and routing. |
| **Broadcast frame** | A frame addressed to every device on the segment, such as an ARP request. |
| **ARP** | Address Resolution Protocol: how a host finds the MAC address for a local IP address. |
| **FDB** | Forwarding database: the bridge's table of which MAC address sits behind which port. |
| **STP** | Spanning Tree Protocol: it finds redundant Layer 2 paths and blocks ports to break loops. |

## Layer 2 and Layer 3: where the address goes

A bridge forwards frames by MAC address, which is Layer 2. IP addresses, the ship's call signs, are Layer 3, and they belong on the bridge interface, not on a port.

### Before and after

Before bridging, the address is on the network interface:

```text
eth3
└── 192.168.1.50/24
```

After bridging, it moves to the bridge:

```text
br0
├── 192.168.1.50/24
└── eth3   (Layer 2 port)
```

Now `br0` owns the address and is what applications use at Layer 3; `eth3` only forwards frames. A port *can* keep its own address, but addresses on both the bridge and a port cause confusing routes, unexpected paths and name problems. Avoid it.

## The `bridge` and `ip link` commands

Two tools cover this module, and both come from the `iproute2` package. One builds the hub, the other looks inside it.

### Build with `ip link`, look with `bridge`

- **`ip link`** creates and wires interfaces. `ip link add name br0 type bridge` makes the bridge; `ip link set eth3 master br0` makes `eth3` a port; `ip link set eth3 nomaster` removes it. `ip -d link show dev br0` adds bridge detail such as the STP state (`-d` means *detail*).
- **`bridge`** inspects the running bridge. `bridge link show` lists ports and their forwarding state. `bridge fdb show` prints the forwarding database, the learned table of MAC addresses and ports.

An easy way to remember it: `ip link` *builds* the switch, `bridge` *looks inside* it.

## Creating a bridge

One command creates the bridge. It exists straight away but starts administratively `DOWN`, so it forwards nothing until you bring it up. You need `sudo`, because creating an interface changes the kernel's network state.

### The command

```bash
sudo ip link add name br0 type bridge
```

### See it in your playground

<!-- astrona:playground:renew -->

Create the bridge and look at it:

```sh
sudo ip link add name br0 type bridge
ip link show dev br0
```

Expect something like:

```text
4: br0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 1a:2b:3c:4d:5e:6f brd ff:ff:ff:ff:ff:ff
```

`br0` is there, but `state DOWN`. Its MAC address is random for now; a bridge normally takes the lowest MAC address of its ports once interfaces are attached. The index (`4:`) and the MAC address are examples.

## Adding a port

To plug an antenna into the hub, bring the interface down, attach it with `master`, then bring both up. These commands can cut your connection, so only ever touch the two spare interfaces, never the management interface that carries your SSH session.

### The commands

```bash
sudo ip link set eth3 down
sudo ip link set eth3 master br0
sudo ip link set br0 up
sudo ip link set eth3 up
```

### See it in your playground

Use one of the two spare interface names from `ip -brief link show`. The examples call it `enp0s2`:

```sh
sudo ip link set enp0s2 master br0
sudo ip link set br0 up
sudo ip link set enp0s2 up
bridge link show
ip link show master br0
```

Expect something like:

```text
3: enp0s2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 100
```

`bridge link show` lists `enp0s2` with `master br0` and `state forwarding`: a live port. `ip link show master br0` shows the same membership from the interface side. The names, priority and cost are examples.

## Common pitfalls

> [!WARNING]
> - **Leaving the IP address on the port after bridging.** The address belongs on `br0`. An address on both the bridge and a port produces confusing routes and traffic paths.
> - **Forgetting to bring the bridge up.** A new bridge is `state DOWN` and forwards nothing until `ip link set br0 up`.
> - **Bridging the management interface.** It carries your SSH session; attaching it to a bridge can cut your link to the ship. Use only the spare interfaces.
