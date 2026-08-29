# Link Aggregation with Linux Bonding

Linux bonding combines multiple network interfaces into one logical interface, commonly named `bond0`.

For example, a machine with two physical interfaces:

```text
eth1
eth2
```

can combine them into:

```text
bond0
```

Applications and network services use `bond0` instead of communicating through `eth1` or `eth2` directly.

Depending on the selected bonding mode, this can provide:

- Network redundancy.
- Automatic failover.
- Distribution of traffic across multiple interfaces.
- Increased total throughput across multiple network connections.

Bonding does not automatically guarantee high availability. Its behaviour depends on the bonding mode, switch configuration, cabling, upstream network design, and whether failures are detected correctly.

## Bond terminology

A bonding configuration contains:

- A **bond interface**, such as `bond0`.
- Two or more **member interfaces**, such as `eth1` and `eth2`.
- A **bonding mode** that controls how the interfaces are used.
- A link-monitoring method that detects interface failures.

The bond interface is sometimes called the **master** interface. Its attached physical interfaces have traditionally been called **slaves**, but **member interfaces** is now the preferred term.

IP addresses should normally be assigned to the bond interface rather than its individual members.

Example:

```text
bond0: 192.168.1.50/24
├── eth1
└── eth2
```

In this configuration, `bond0` owns the IP address. The member interfaces transport traffic on behalf of the bond.

## Common bonding modes

Linux supports several bonding modes. The correct mode depends on whether the goal is failover, load distribution, or integration with a switch using the Link Aggregation Control Protocol (LACP).

### Mode 1: Active-backup

Active-backup mode uses one interface for traffic while the other member interfaces remain ready as backups.

```text
bond0
├── eth1 — active
└── eth2 — backup
```

If the active interface fails, another available member becomes active.

This mode is configured as:

```text
mode=1
```

or:

```text
mode=active-backup
```

Active-backup mode provides:

- Simple automatic failover.
- One active interface at a time.
- No requirement for a switch-side link aggregation group.
- Compatibility with most switches.

It does not combine the bandwidth of all member interfaces. If two 1 Gbit/s interfaces are bonded, the bond normally still provides up to 1 Gbit/s of active bandwidth.

Active-backup mode is often a good starting point when redundancy is more important than additional throughput.

### Mode 5: Adaptive transmit load balancing

Adaptive transmit load balancing distributes outgoing traffic between available member interfaces.

Incoming traffic is normally received through one interface.

This mode is configured as:

```text
mode=5
```

or:

```text
mode=balance-tlb
```

Balance-TLB provides:

- Distribution of outgoing traffic.
- Automatic failover.
- No requirement for a switch-side link aggregation group.

Because incoming and outgoing traffic are handled differently, the performance benefit depends on the traffic pattern. A single network connection should not be expected to use the combined bandwidth of all interfaces.

### Mode 4: IEEE 802.3ad LACP

Mode 4 creates a dynamic link aggregation group using IEEE 802.3ad and the Link Aggregation Control Protocol.

This mode is configured as:

```text
mode=4
```

or:

```text
mode=802.3ad
```

LACP allows the Linux machine and network switch to negotiate which links belong to the aggregation group.

It can provide:

- Link redundancy.
- Distribution of traffic across multiple interfaces.
- Higher total throughput when multiple network flows are active.
- Detection and management of links within the aggregation group.

LACP requires compatible configuration on both the Linux machine and the connected switch. The switch ports must belong to the same LACP aggregation group.

A single network flow normally uses only one physical interface because traffic is distributed using a hash. Multiple simultaneous flows can be distributed across different member interfaces.

Two 1 Gbit/s links may therefore provide close to 2 Gbit/s of total capacity across multiple flows, but a single transfer will normally remain limited to approximately 1 Gbit/s.

## Comparing common bonding modes

| Mode | Name | Primary purpose | Switch configuration | Uses multiple active links |
|---|---|---|---|---|
| `1` | `active-backup` | Redundancy and failover | Not normally required | No |
| `5` | `balance-tlb` | Outbound load distribution | Not normally required | For outgoing traffic |
| `4` | `802.3ad` | Link aggregation with LACP | Required | Yes |

## Link monitoring

A bond needs a way to detect whether a member interface is still operational.

One common method is Media Independent Interface monitoring, known as **MII monitoring**.

The following setting checks the link state every 100 milliseconds:

```text
miimon=100
```

MII monitoring can detect conditions such as:

- A disconnected network cable.
- A disabled switch port.
- A failed physical interface.
- Loss of the local Ethernet carrier.

MII monitoring only checks the local link state. It does not confirm that the default gateway or a remote service is reachable.

For example, the link may remain operational even if a router farther upstream has failed.

## Creating a temporary bond

The `ip` command can create a bond directly in the running Linux system:

```bash
sudo ip link add name bond0 type bond mode active-backup miimon 100
```

This command creates:

- A bond named `bond0`.
- An active-backup configuration.
- MII link monitoring every 100 milliseconds.

The configuration is temporary and is normally lost when the machine restarts.

Before adding an interface to a bond, bring it down:

```bash
sudo ip link set eth1 down
sudo ip link set eth2 down
```

Attach the interfaces to the bond:

```bash
sudo ip link set eth1 master bond0
sudo ip link set eth2 master bond0
```

Enable the bond and its member interfaces:

```bash
sudo ip link set bond0 up
sudo ip link set eth1 up
sudo ip link set eth2 up
```

These commands can interrupt network connectivity. Do not modify the interface used for your current SSH session unless you have console access or another recovery method.

## Assigning an IP address to the bond

An IP address should normally be assigned to the bond instead of its member interfaces:

```bash
sudo ip addr add 192.168.1.50/24 dev bond0
```

If the machine needs to communicate with other networks, it may also require a default route:

```bash
sudo ip route add default via 192.168.1.1 dev bond0
```

The example values must be replaced with addresses appropriate for the local network.

Member interfaces should normally not keep their own Layer 3 addresses after joining the bond. The bond becomes the logical Layer 3 interface used by the operating system.

## Inspecting a bond

Display the bond interface:

```bash
ip link show bond0
```

Display its assigned addresses:

```bash
ip addr show dev bond0
```

Display the attached member interfaces:

```bash
ip link show master bond0
```

Detailed bonding information is available through:

```bash
cat /proc/net/bonding/bond0
```

Example output may include:

```text
Bonding Mode: fault-tolerance (active-backup)
MII Status: up
MII Polling Interval (ms): 100
Currently Active Slave: eth1
```

Important fields include:

- `Bonding Mode`: The mode used by the bond.
- `MII Status`: Whether the bond currently detects a working link.
- `MII Polling Interval`: How frequently the link state is checked.
- `Currently Active Slave`: The member currently carrying traffic in active-backup mode.
- `Link Failure Count`: The number of detected failures for a member.
- `Permanent HW addr`: The original MAC address of a member interface.

The kernel interface still uses the historical word `Slave` in some output even though the interfaces can be described as bond members in documentation.

## Temporary and persistent configuration

Bonding created with the `ip` command is runtime configuration. It normally disappears after a restart.

A persistent bond should be configured using the network-management system provided by the Linux distribution, such as:

- NetworkManager.
- Netplan.
- `systemd-networkd`.
- `ifupdown`.
- Distribution-specific network configuration files.

Do not configure the same interfaces through multiple network-management systems at the same time. Conflicting configurations can cause interfaces to change state unexpectedly.

## High-availability considerations

Bonding protects against certain failures, but it does not remove every single point of failure.

For meaningful redundancy, consider whether the member interfaces use:

- Different physical network cards.
- Different cables.
- Different switch ports.
- Different switches.
- Independent power sources.
- Independent upstream network paths.

Connecting both interfaces to the same switch protects against a cable or port failure, but it does not protect against failure of the entire switch.

When member interfaces connect to different switches, the switches must support the chosen design. Multi-switch LACP normally requires technologies such as switch stacking, MLAG, or an equivalent vendor-specific feature.