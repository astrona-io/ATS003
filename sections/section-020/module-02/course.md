# Software Bridging

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-020/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-02/playground
> astrona destroy linux-bridging-playground
> ```

A Linux **software bridge** is a virtual Layer 2 switch built into the kernel. Like a physical switch, it connects several network interfaces and forwards Ethernet frames between them by MAC address. The interfaces attached to a bridge are its **bridge ports** (or **member interfaces**).

For example:

```text
                     Linux host

eth3 ──────────────── br0 ──────────────── vnet0
Physical interface   Software bridge       Virtual interface
```

Here `br0` lets a virtual machine on `vnet0` reach the physical network through `eth3`. Software bridges are the backbone of virtual-machine and container networking, network namespaces, Kubernetes and other orchestrators, software-defined networking, and Linux routers and firewalls.

## Learning objectives

After this module you can:

- Explain what a Linux software bridge is, why it operates at Layer 2, and why an IP address belongs on the bridge rather than on a port.
- Create a temporary bridge with `ip link`, attach an interface with `master`, and confirm membership with `bridge link show`.
- Describe how a bridge learns MAC addresses into its forwarding database (FDB) and read it with `bridge fdb show`.
- Explain how a Layer 2 loop forms and what STP does about it, and enable or disable STP on a bridge.
- Move an IP address from a port to the bridge and verify the result with `ip addr show`.
- Explain why an `ip`-created bridge is lost on reboot, and state how a bridge differs from a bond.

## Before you start

This module assumes you can open a shell, run commands with `sudo`, and have seen interface names like `enp0s2` and a prefixed IPv4 address such as `192.168.60.10/24`. Ethernet frame, MAC address, Layer 2 and Layer 3, ARP, DHCP, and STP are all defined as they come up. The bonding module is useful background for the closing comparison but is not required.

Open a shell on the playground VM with `astrona ssh astro-linux-bridging-playground`. The machine has three usable interfaces: one management NIC that carries your SSH session and holds an address — leave it alone — and two spare NICs, `DOWN` and address-less, both on the **same** isolated `192.168.60.0/24` segment. Both spares sharing one segment is deliberate: it lets the STP checkpoint build a real Layer 2 loop. That segment has no other host, no DHCP server, and no LACP switch, so dynamically learned FDB entries and DHCP-on-a-bridge cannot be shown here — the text says so where each comes up.

## Where this fits

This section covers three ways Linux joins interfaces. A **bridge** (here) is a Layer 2 switch: it connects segments and virtual machines so frames pass between them. A **bond** (previous module) makes several NICs act as one link for redundancy or capacity. **Static routing** (next module) is Layer 3 — choosing which interface a packet leaves by. The three stack: a bridge port can be a bond, and the bridge itself gets the IP address and the routes.

## Key terms

| Term | Meaning in this module |
|---|---|
| **Ethernet frame** | The unit of data on a local segment; carries a source and destination MAC address. |
| **MAC address** | The hardware address of an interface, such as `52:54:00:11:22:33`; used for local delivery. |
| **Layer 2** | Local delivery on one segment, by MAC address. A bridge works here. |
| **Layer 3** | Delivery between networks, by IP address and routing. |
| **Broadcast frame** | A frame addressed to every device on the segment, such as an ARP request. |
| **ARP** | Address Resolution Protocol — how a host finds the MAC for a given local IP. |
| **FDB** | Forwarding database — the bridge's table of "which MAC is behind which port". |
| **STP** | Spanning Tree Protocol — detects redundant Layer 2 paths and blocks ports to break loops. |

## Layer 2 and Layer 3: where the address goes

A bridge forwards frames by MAC address — that is Layer 2. IP addresses are Layer 3, and they belong on the bridge interface, not on a port.

Before bridging, the address is on the NIC:

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

Now `br0` owns the address and is what applications use for Layer 3; `eth3` just forwards frames. A port *can* technically keep its own address, but addresses on both the bridge and a port cause confusing routes, unexpected paths, and name-resolution problems — avoid it.

## The `bridge` and `ip link` commands

Two tools cover this module, both from `iproute2`:

- **`ip link`** creates and wires interfaces: `ip link add name br0 type bridge` makes the bridge; `ip link set eth3 master br0` makes `eth3` a port; `ip link set eth3 nomaster` removes it. `ip -d link show dev br0` adds bridge detail such as STP state (`-d` = *detail*).
- **`bridge`** inspects the running bridge. `bridge link show` lists ports and their forwarding state. `bridge fdb show` prints the **forwarding database** (FDB) — the learned "MAC → port" table.

Memory hook: `ip link` *builds* the switch, `bridge` *looks inside* it.

## Creating a bridge

```bash
sudo ip link add name br0 type bridge
```

The bridge exists immediately but starts administratively `DOWN` — it forwards nothing until you bring it up. `sudo` is needed because creating an interface changes kernel network state.

> [!TIP]
> **Try it — create the bridge and see it exist but stay down**
>
> ```sh
> sudo ip link add name br0 type bridge
> ip link show dev br0
> ```
>
> Expect something like:
>
> ```text
> 4: br0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
>     link/ether 1a:2b:3c:4d:5e:6f brd ff:ff:ff:ff:ff:ff
> ```
>
> `br0` is present but `state DOWN`. Its MAC is random for now; a bridge normally adopts the lowest MAC among its ports once interfaces are attached. Index (`4:`) and MAC are examples.

## Adding a port

Bring the interface down, attach it with `master`, then bring both up:

```bash
sudo ip link set eth3 down
sudo ip link set eth3 master br0
sudo ip link set br0 up
sudo ip link set eth3 up
```

> [!WARNING]
> These commands can interrupt connectivity. Only ever touch the two spare NICs, never the management interface carrying your SSH session.

> [!TIP]
> **Try it — attach one NIC and inspect bridge membership**
>
> Use one of the two spare interface names from `ip -brief link show`. The examples call it `enp0s2`.
>
> ```sh
> sudo ip link set enp0s2 master br0
> sudo ip link set br0 up
> sudo ip link set enp0s2 up
> bridge link show
> ip link show master br0
> ```
>
> Expect something like:
>
> ```text
> 3: enp0s2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 100
> ```
>
> `bridge link show` lists `enp0s2` with `master br0` and `state forwarding` — a live port. `ip link show master br0` shows the same membership from the interface side. Names, priority, and cost are examples.

## How a bridge learns: the forwarding database

A bridge builds its **forwarding database** (FDB) by watching the *source* MAC of every frame it receives and noting which port it arrived on:

```text
MAC address          Bridge port
52:54:00:11:22:33    eth3
52:54:00:aa:bb:cc    vnet0
```

For each incoming frame the bridge:

1. learns the source MAC and the incoming port;
2. looks up the destination MAC in the FDB;
3. if known, forwards the frame out that one port;
4. if unknown, floods it out every other eligible port.

Broadcast frames, such as ARP requests, are always flooded to the other ports. This is exactly how a physical Ethernet switch behaves.

> [!TIP]
> **Try it — read the forwarding database**
>
> ```sh
> bridge fdb show br br0
> ```
>
> On this idle, single-host segment expect mostly `permanent` entries — the port's own MAC and multicast groups — and few or no dynamically learned ones:
>
> ```text
> 52:54:00:aa:bb:cc dev enp0s2 master br0 permanent
> 33:33:00:00:00:01 dev enp0s2 self permanent
> ```
>
> Dynamic "MAC → port" entries only appear once another host sends frames through the bridge, and nothing else is on this segment. The learning mechanism is real; there is just no traffic here to populate it.

## Moving the IP to the bridge

If the port already has an address, remove it from the port and add it to the bridge; put any default route on the bridge too:

```bash
sudo ip addr del 192.168.1.50/24 dev eth3
sudo ip addr add 192.168.1.50/24 dev br0
sudo ip route add default via 192.168.1.1 dev br0
```

Moving an address can immediately break connections that were using it.

> [!TIP]
> **Try it — put the IP on the bridge, not the port**
>
> The spare NICs face `192.168.60.0/24`, and they have no address to move, so this just adds one to `br0`:
>
> ```sh
> sudo ip addr add 192.168.60.10/24 dev br0
> ip addr show dev br0
> ```
>
> Expect something like:
>
> ```text
> 4: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ...
>     inet 192.168.60.10/24 scope global br0
>        valid_lft forever preferred_lft forever
> ```
>
> The address is on `br0`. `ip addr show dev enp0s2` shows the port still has none — the port carries frames at Layer 2 while the bridge is the Layer 3 interface the host routes through. Remove it with `sudo ip addr del 192.168.60.10/24 dev br0`.

## Using DHCP with a bridge

When DHCP is used, the DHCP client runs on the bridge, not on a port — conceptually `DHCP client → br0 → eth3`. The exact configuration depends on the distribution's network-management system (NetworkManager, Netplan, `systemd-networkd`, `ifupdown`, …). Never run DHCP clients on both the bridge and a member at once.

> This playground has no DHCP server on its isolated segment, so a DHCP client on `br0` would get no answer. The idea matters in practice; the mechanics need a server the sandbox does not provide.

## Spanning Tree Protocol

Connecting two bridges — or attaching two ports of one bridge to the same segment — creates a **Layer 2 loop**. Frames then circulate endlessly, and broadcasts multiply until they saturate the network: a **broadcast storm**, with duplicate frames, MAC addresses flapping between ports, high CPU, and lost connectivity.

The **Spanning Tree Protocol (STP)** detects redundant Layer 2 paths and puts selected ports into a `blocking` state so exactly one path stays active. Toggle it per bridge:

```bash
sudo ip link set dev br0 type bridge stp_state 1   # on
sudo ip link set dev br0 type bridge stp_state 0   # off
```

A bridge with one physical and one virtual port has no redundant path and does not need STP. More complex topologies do.

> [!TIP]
> **Try it — build a loop on purpose and watch STP block a port**
>
> Both spare NICs face the **same** segment, so bridging both is a deliberate loop. Enable STP **before** the second port comes up, so the loop is managed from the start rather than storming first:
>
> ```sh
> sudo ip link set dev br0 type bridge stp_state 1
> sudo ip link set enp0s3 master br0
> sudo ip link set enp0s3 up
> bridge link show
> ```
>
> Give STP's default timers about 30 seconds to settle, then re-run `bridge link show`. Expect something like:
>
> ```text
> 3: enp0s2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 100
> 4: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state blocking priority 32 cost 100
> ```
>
> One port is `forwarding`, the other `blocking` — STP kept the segment reachable while breaking the loop. `ip -d link show dev br0` shows `stp_state 1`. Setting `stp_state 0` returns both ports to `forwarding` and the loop goes live; broadcast traffic then climbs, so re-enable STP or run `sudo ip link set enp0s3 down` to calm it. Names, priority, and cost are examples.

## Removing a port and deleting the bridge

Detach a port with `nomaster`, then delete the bridge once no ports remain:

```bash
sudo ip link set enp0s3 down
sudo ip link set enp0s3 nomaster
sudo ip link delete br0 type bridge
```

Deleting the bridge removes its runtime configuration and interrupts anything that was using it.

## Runtime versus persistent configuration

Bridges built with `ip` are runtime-only — normally gone after a restart. A persistent bridge is defined through the distribution's network-management system. Do not configure the same bridge through more than one such system; conflicting configurations make addresses, routes, and membership change unexpectedly.

> [!TIP]
> **Try it — confirm the runtime bridge does not survive a reboot**
>
> This restarts the whole VM and drops your SSH session for about a minute; reconnect with `astrona ssh astro-linux-bridging-playground`.
>
> ```sh
> sudo reboot
> ```
>
> After reconnecting:
>
> ```sh
> ip link show dev br0
> ```
>
> Expect:
>
> ```text
> Device "br0" does not exist.
> ```
>
> `br0` and every port assignment you made with `ip` are gone. Anything that must return after a reboot has to be written into one of the network-management systems above.

## Bridges compared with bonds

A bridge and a bond solve different problems.

| Technology | Primary purpose | Comparable physical device |
|---|---|---|
| Bridge | Connect multiple Layer 2 segments / VMs | Ethernet switch |
| Bond | Combine interfaces for redundancy or distribution | Link aggregation group |

They compose — a bond can be a single bridge port:

```text
br0
└── bond0
    ├── eth1
    └── eth2
```

`eth1` and `eth2` provide the physical links; `bond0` gives redundancy or distribution; `br0` gives Layer 2 connectivity and holds the IP address.

> [!WARNING]
> **Common pitfalls**
>
> - **Leaving the IP on the port after bridging.** The address belongs on `br0`. An address on both the bridge and a port produces confusing routes and traffic paths.
> - **Bridging two ports onto the same segment with STP off.** That is a loop. Broadcast frames storm within seconds. Enable `stp_state 1` first, or keep the second port down.
> - **Expecting `bridge fdb show` to be full on an idle segment.** Dynamic entries need traffic from other hosts. On a single-host segment you see mostly `permanent` entries — that is normal, not a broken bridge.
> - **Confusing a bridge with a bond.** A bridge connects different segments (switch); a bond merges NICs into one link (aggregation). They are not interchangeable.
> - **Deleting a bridge with ports still attached.** Detach each port with `nomaster` first, then `ip link delete br0`.
