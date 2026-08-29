# Software Bridging

A Linux software bridge is a virtual Layer 2 switch implemented inside the Linux kernel.

Like a physical network switch, a bridge connects multiple network interfaces and forwards Ethernet frames between them. The interfaces connected to a bridge are called **bridge ports** or **member interfaces**.

For example:

```text
                     Linux host
                       
eth3 ──────────────── br0 ──────────────── vnet0
Physical interface   Software bridge       Virtual interface
```

In this example, the bridge allows a device connected through `vnet0` to communicate with the physical network through `eth3`.

Software bridges are commonly used by:

- Virtual machines.
- Container platforms.
- Network namespaces.
- Kubernetes and other orchestration systems.
- Software-defined networking platforms.
- Linux routers and firewalls.

## Layer 2 and Layer 3 responsibilities

A bridge primarily operates at Layer 2 of the network model. It forwards Ethernet frames using MAC addresses.

IP addresses belong to Layer 3.

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
- Ethernet frames can be forwarded through `eth3`.

A Linux bridge port can technically have its own IP address, but this is normally avoided. Assigning addresses to both the bridge and its ports can create confusing routes, unexpected traffic paths, and name-resolution problems.

## How a bridge forwards traffic

A Linux bridge examines the source MAC address of each Ethernet frame it receives.

It uses this information to build a forwarding database, commonly called the **FDB**.

The forwarding database records which MAC addresses are reachable through which bridge ports.

Example:

```text
MAC address          Bridge port
52:54:00:11:22:33    eth3
52:54:00:aa:bb:cc    vnet0
```

When the bridge receives a frame:

1. It learns the source MAC address and incoming port.
2. It looks up the destination MAC address in the FDB.
3. If the destination is known, it forwards the frame through the associated port.
4. If the destination is unknown, it sends the frame through the other eligible ports.

Broadcast frames, such as Address Resolution Protocol (ARP) requests, are also forwarded to the other eligible bridge ports.

This behaviour is similar to a physical Ethernet switch.

## Creating a temporary bridge

Create a bridge named `br0`:

```bash
sudo ip link add name br0 type bridge
```

The bridge exists immediately, but it is initially disabled.

Display the new interface:

```bash
ip link show dev br0
```

This configuration is temporary and normally disappears after the machine restarts.

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

These commands can interrupt network connectivity. Do not modify the interface used for your current SSH connection unless you have console access or another recovery method.

## Moving an existing IP address

If `eth3` already has an IP address, that address should normally be moved to `br0`.

Display the current address configuration:

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

Replace the example addresses with values appropriate for the local network.

Moving an address from an interface can immediately interrupt active network connections.

## Using DHCP with a bridge

When DHCP is used, the DHCP client should normally run on the bridge rather than on an individual bridge port.

Conceptually, the configuration changes from:

```text
DHCP client → eth3
```

to:

```text
DHCP client → br0 → eth3
```

The exact command depends on the Linux distribution and its network-management system.

Possible network-management systems include:

- NetworkManager.
- Netplan.
- `systemd-networkd`.
- `ifupdown`.
- Distribution-specific networking services.

Avoid running DHCP clients on both the bridge and its member interfaces.

## Inspecting bridge membership

Display the interfaces attached to Linux bridges:

```bash
bridge link show
```

Example output:

```text
3: eth3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding
```

Important fields include:

- `eth3`: The bridge port.
- `master br0`: The bridge to which the interface belongs.
- `UP`: The interface has been enabled.
- `LOWER_UP`: Linux detects an active link.
- `state forwarding`: The port can forward Ethernet frames.

Display only ports attached to `br0`:

```bash
ip link show master br0
```

Display information about the bridge interface:

```bash
ip link show dev br0
```

Display the bridge's IP addresses:

```bash
ip addr show dev br0
```

## Inspecting the forwarding database

Display the bridge forwarding database:

```bash
bridge fdb show
```

To display entries associated with a specific bridge:

```bash
bridge fdb show br br0
```

The output shows MAC addresses learned through the bridge ports.

Some entries are learned dynamically from network traffic. Others are created permanently by the kernel or administrator.

## Spanning Tree Protocol

Connecting bridges incorrectly can create a Layer 2 loop.

A loop can cause Ethernet frames to circulate repeatedly, potentially resulting in:

- Broadcast storms.
- Duplicate frames.
- Rapid MAC-address movement.
- High CPU and network utilization.
- Loss of network connectivity.

The Spanning Tree Protocol (STP) can detect redundant Layer 2 paths and block selected ports to prevent loops.

Display the bridge configuration:

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

Whether STP should be enabled depends on the network design. A simple bridge with one physical interface and one virtual interface does not normally contain a redundant path. More complex bridge topologies require careful loop prevention.

## Removing an interface from a bridge

Bring the member interface down:

```bash
sudo ip link set eth3 down
```

Detach it from the bridge:

```bash
sudo ip link set eth3 nomaster
```

Enable the interface again if required:

```bash
sudo ip link set eth3 up
```

The `nomaster` argument removes the interface from its current bridge or other master device.

Before deleting a bridge, ensure that it is no longer required and that its member interfaces have been detached.

Delete the bridge:

```bash
sudo ip link delete br0 type bridge
```

Deleting the bridge removes its runtime configuration and can interrupt network connectivity.

## Temporary and persistent configuration

Bridges created with the `ip` command are runtime-only configurations. They normally disappear after the machine restarts.

A persistent bridge should be defined using the network-management system provided by the Linux distribution.

Do not configure the same bridge and interfaces through multiple network-management systems at the same time. Conflicting configurations can cause addresses, routes, and bridge membership to change unexpectedly.

## Bridges compared with bonds

A bridge and a bond solve different networking problems.

| Technology | Primary purpose | Comparable physical device |
|---|---|---|
| Bridge | Connect multiple Layer 2 network segments | Ethernet switch |
| Bond | Combine interfaces for redundancy or traffic distribution | Link aggregation group |

A bridge connects interfaces so Ethernet frames can pass between them. A bond combines interfaces so they behave as one logical network link.

The two technologies can also be used together:

```text
br0
└── bond0
    ├── eth1
    └── eth2
```

In this configuration:

- `eth1` and `eth2` provide the physical links.
- `bond0` provides redundancy or traffic distribution.
- `br0` provides Layer 2 connectivity.
- The IP address is normally assigned to `br0`.

The correct arrangement depends on the operating system, virtualization platform, and network design.