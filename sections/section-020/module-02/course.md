# Software Bridging

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-020/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-02/playground
> astrona destroy linux-bridging-playground
> ```

A Linux **software bridge** is a virtual Layer 2 switch built into the Linux kernel.

Like a physical network switch, a bridge connects multiple network interfaces and forwards Ethernet frames between them. A **network interface** is the point where the operating system connects to a network — a physical network card, or a virtual one belonging to a virtual machine or container. The interfaces connected to a bridge are called **bridge ports** or **member interfaces**.

For example:

```text
                     Linux host

eth3 ──────────────── br0 ──────────────── vnet0
Physical interface   Software bridge       Virtual interface
```

Here the bridge lets a device connected through `vnet0` talk to the physical network through `eth3`.

Software bridges are commonly used by:

- Virtual machines.
- Container platforms.
- Network namespaces (isolated network stacks inside one Linux host).
- Kubernetes and other orchestration systems.
- Software-defined networking platforms.
- Linux routers and firewalls.

## Key terms

| Term | Meaning in this chapter |
|---|---|
| **Ethernet frame** | The unit of data sent on a local network. Carries a source and destination MAC address. |
| **MAC address** | The hardware address of a network interface, such as `52:54:00:11:22:33`. Used to deliver frames on the local segment. |
| **Layer 2** | Local delivery on one network segment, using MAC addresses (Ethernet). A bridge works here. |
| **Layer 3** | Delivery between networks, using IP addresses and routing. |
| **Broadcast frame** | A frame addressed to every device on the segment, such as an ARP request. |
| **ARP** | Address Resolution Protocol — how a host finds the MAC address for a given IP on the local segment. |
| **DHCP** | A protocol a host uses to lease an IP address and related settings from a server on the network. |
| **STP** | Spanning Tree Protocol — detects redundant Layer 2 paths and blocks ports to stop loops. |

## Layer 2 and Layer 3 responsibilities

A bridge works mainly at Layer 2. It forwards Ethernet frames using MAC addresses. IP addresses belong to Layer 3.

When a physical interface becomes a bridge port, its Layer 3 configuration should normally be moved to the bridge interface.

Before bridging:

```text
eth3
└── 192.168.1.50/24
```

After bridging:

```text
br0
├── 192.168.1.50/24
└── eth3
```

In the second configuration:

- `br0` owns the IP address.
- `eth3` acts as a Layer 2 bridge port.
- Applications use `br0` for Layer 3 communication.
- Ethernet frames are still forwarded through `eth3`.

A Linux bridge port can technically keep its own IP address, but this is normally avoided. Assigning addresses to both the bridge and its ports can create confusing routes, unexpected traffic paths, and name-resolution problems.

## How a bridge forwards traffic

A Linux bridge looks at the source MAC address of every Ethernet frame it receives and uses it to build a **forwarding database**, commonly called the **FDB**.

The forwarding database records which MAC addresses are reachable through which bridge ports.

Example:

```text
MAC address          Bridge port
52:54:00:11:22:33    eth3
52:54:00:aa:bb:cc    vnet0
```

When the bridge receives a frame:

1. It learns the source MAC address and the incoming port.
2. It looks up the destination MAC address in the FDB.
3. If the destination is known, it forwards the frame out the associated port.
4. If the destination is unknown, it floods the frame out the other eligible ports.

Broadcast frames, such as ARP requests, are also sent out the other eligible bridge ports. This behaviour is like a physical Ethernet switch.

## Creating a temporary bridge

Create a bridge named `br0`:

```bash
sudo ip link add name br0 type bridge
```

The bridge exists immediately but starts out disabled (administratively down).

Display the new interface:

```bash
ip link show dev br0
```

This configuration is temporary and normally disappears after the machine restarts. (`sudo` is needed because creating an interface changes kernel network state; a plain user cannot.)

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
> `br0` is present but `state DOWN` — it forwards nothing yet. Its MAC address is random for now; a bridge normally adopts the lowest MAC among its ports once interfaces are attached. The interface index (`4:`) and MAC are examples.

## Adding an interface to the bridge

Before adding a physical interface to a bridge, bring it down:

```bash
sudo ip link set eth3 down
```

Attach `eth3` to `br0`:

```bash
sudo ip link set eth3 master br0
```

The `master br0` argument makes `eth3` a port of the bridge.

Enable the bridge and its member interface:

```bash
sudo ip link set br0 up
sudo ip link set eth3 up
```

**Warning:** these commands can interrupt network connectivity. Do not modify the interface used for your current SSH connection unless you have console access or another recovery method. In the playground, only ever touch the two spare NICs, never the management interface.

> [!TIP]
> **Try it — enslave one NIC and inspect bridge membership**
>
> Use one of the two spare interface names from `ip -brief link show` (not your SSH interface). The examples below call it `enp0s2`.
>
> ```sh
> sudo ip link set enp0s2 master br0
> sudo ip link set br0 up
> sudo ip link set enp0s2 up
> bridge link show
> ip link show master br0
> bridge fdb show br br0
> ```
>
> Expect something like:
>
> ```text
> 3: enp0s2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 100
> ```
>
> `bridge link show` lists `enp0s2` with `master br0` and `state forwarding` — it is now a live port. `ip link show master br0` shows the same members from the interface side. `bridge fdb show br br0` mostly lists `permanent` entries (the port's own MAC and multicast groups); dynamic learned entries only appear once another host sends frames through the bridge, which nothing does on this isolated segment. Names, priority, and cost are examples.

## Moving an existing IP address

If `eth3` already has an IP address, that address should normally be moved to `br0`.

Show the current address configuration:

```bash
ip addr show dev eth3
```

Remove an example address from `eth3`:

```bash
sudo ip addr del 192.168.1.50/24 dev eth3
```

Assign the address to `br0`:

```bash
sudo ip addr add 192.168.1.50/24 dev br0
```

If a default route is required, it should also use the bridge:

```bash
sudo ip route add default via 192.168.1.1 dev br0
```

Replace the example addresses with values appropriate for the local network. Moving an address from an interface can immediately interrupt active network connections that were using it.

> [!TIP]
> **Try it — put the IP on the bridge, not the port**
>
> The playground's spare NICs face the `192.168.60.0/24` segment, so pick an address there. The spare ports have no address to move, so this just adds one to `br0`:
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
> The address lands on `br0`. `ip addr show dev enp0s2` shows the port still has none — the port carries frames at Layer 2 while the bridge is the Layer 3 interface the host routes through. Remove it again with `sudo ip addr del 192.168.60.10/24 dev br0`.

## Using DHCP with a bridge

When DHCP is used, the DHCP client should normally run on the bridge rather than on an individual bridge port.

Conceptually the configuration changes from:

```text
DHCP client → eth3
```

to:

```text
DHCP client → br0 → eth3
```

The exact command depends on the Linux distribution and its network-management system. Possible systems include:

- NetworkManager.
- Netplan.
- `systemd-networkd`.
- `ifupdown`.
- Distribution-specific networking services.

Avoid running DHCP clients on both the bridge and its member interfaces at the same time.

> This module's playground has no DHCP server on its isolated segment, so a DHCP client on `br0` would have nothing to answer it. The idea matters in practice; the mechanics need a DHCP server the sandbox does not provide.

## Inspecting bridge membership

Show the interfaces attached to Linux bridges:

```bash
bridge link show
```

Example output:

```text
3: eth3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding
```

Important fields:

- `eth3` — the bridge port.
- `master br0` — the bridge the interface belongs to.
- `UP` — the interface is enabled.
- `LOWER_UP` — Linux detects an active link on it.
- `state forwarding` — the port can forward Ethernet frames.

Show only ports attached to `br0`:

```bash
ip link show master br0
```

Show the bridge interface itself:

```bash
ip link show dev br0
```

Show the bridge's IP addresses:

```bash
ip addr show dev br0
```

## Inspecting the forwarding database

Show the bridge forwarding database:

```bash
bridge fdb show
```

Show entries for one bridge:

```bash
bridge fdb show br br0
```

The output lists MAC addresses learned through the bridge ports. Some entries are learned dynamically from traffic; others are `permanent`, created by the kernel or an administrator. On an idle segment with no other hosts, expect mostly permanent entries.

## Spanning Tree Protocol

Connecting bridges — or connecting two ports of one bridge to the same segment — can create a **Layer 2 loop**.

A loop lets Ethernet frames circulate endlessly, which can cause:

- Broadcast storms (broadcast frames multiplying until they saturate the network).
- Duplicate frames.
- Rapid MAC-address movement between ports.
- High CPU and network utilization.
- Loss of connectivity.

The **Spanning Tree Protocol (STP)** detects redundant Layer 2 paths and blocks selected ports so exactly one path stays active.

Show the bridge configuration, including STP fields:

```bash
ip -d link show dev br0
```

Enable STP on the bridge:

```bash
sudo ip link set dev br0 type bridge stp_state 1
```

Disable STP:

```bash
sudo ip link set dev br0 type bridge stp_state 0
```

Whether STP should be on depends on the topology. A bridge with one physical interface and one virtual interface has no redundant path and does not need it. More complex topologies need careful loop prevention.

> [!TIP]
> **Try it — build a loop on purpose and watch STP block a port**
>
> Both spare NICs in this playground face the **same** segment, so bridging both is a deliberate loop. Enable STP **before** the second port comes up, so the loop is managed from the start rather than storming first:
>
> ```sh
> sudo ip link set dev br0 type bridge stp_state 1
> sudo ip link set enp0s3 master br0
> sudo ip link set enp0s3 up
> bridge link show
> ```
>
> Give STP its default timers about 30 seconds to settle, then re-run `bridge link show`. Expect something like:
>
> ```text
> 3: enp0s2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 100
> 4: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state blocking priority 32 cost 100
> ```
>
> One port is `forwarding`, the other `blocking` — STP kept the segment reachable while breaking the loop. `ip -d link show dev br0` shows `stp_state 1`. If you set `stp_state 0` again, both ports return to `forwarding` and the loop is live; broadcast traffic can then climb, so re-enable STP or run `sudo ip link set enp0s3 down` to calm it. Port names, priority, and cost are examples.

## Removing an interface from a bridge

Bring the member interface down:

```bash
sudo ip link set eth3 down
```

Detach it from the bridge:

```bash
sudo ip link set eth3 nomaster
```

Bring the interface back up if it is still needed:

```bash
sudo ip link set eth3 up
```

The `nomaster` argument removes the interface from its current bridge (or other master device).

Before deleting a bridge, make sure it is no longer needed and its ports have been detached.

Delete the bridge:

```bash
sudo ip link delete br0 type bridge
```

Deleting the bridge removes its runtime configuration and can interrupt connectivity for anything that was using it.

## Temporary and persistent configuration

Bridges created with the `ip` command are runtime-only. They normally disappear after the machine restarts.

A persistent bridge should be defined through the network-management system your Linux distribution provides.

Do not configure the same bridge and interfaces through more than one network-management system at once. Conflicting configurations can make addresses, routes, and bridge membership change unexpectedly.

> [!TIP]
> **Try it — confirm the runtime bridge does not survive a reboot**
>
> This restarts the whole VM and drops your SSH session for a minute. That is safe in a throwaway playground; reconnect afterwards with `astrona ssh linux-bridging-playground`.
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
| Bridge | Connect multiple Layer 2 network segments | Ethernet switch |
| Bond | Combine interfaces for redundancy or traffic distribution | Link aggregation group |

A bridge connects interfaces so Ethernet frames can pass between them. A bond combines interfaces so they behave as one logical link.

The two can be used together:

```text
br0
└── bond0
    ├── eth1
    └── eth2
```

In this arrangement:

- `eth1` and `eth2` provide the physical links.
- `bond0` provides redundancy or traffic distribution.
- `br0` provides Layer 2 connectivity.
- The IP address is normally assigned to `br0`.

The right arrangement depends on the operating system, virtualization platform, and network design.
