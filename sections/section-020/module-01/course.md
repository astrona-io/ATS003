# Link Aggregation with Linux Bonding

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-020/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-01/playground
> astrona destroy linux-bonding-playground
> ```

A **network interface** is the point where the operating system connects to a network. It is usually a network card (a NIC) or a virtual equivalent, it has a name such as `eth0` or `enp0s2`, and it can carry one or more IP addresses.

Linux **bonding** takes several network interfaces and presents them to the rest of the system as one interface, commonly named `bond0`. `bond0` is a *logical* interface: it is software in the kernel that sits on top of real network cards, not a physical port you can plug a cable into.

For example, a machine with two physical interfaces:

```text
eth1
eth2
```

can combine them into:

```text
bond0
```

Applications and network services then use `bond0` instead of talking to `eth1` or `eth2` directly.

Depending on the bonding mode you choose, this can provide:

- **Redundancy** — more than one interface can do the job, so one can fail without an outage.
- **Automatic failover** — traffic moves to a working interface when the active one fails.
- **Traffic distribution** — outgoing (and sometimes incoming) traffic is spread across several interfaces.
- **Higher total throughput** — more combined data-per-second capacity across multiple connections.

Bonding does not automatically guarantee high availability. Its behaviour depends on the bonding mode, the switch configuration, the cabling, the upstream network design, and whether failures are actually detected.

## Key terms

| Term | Meaning in this chapter |
|---|---|
| **MAC address** | The hardware address of an interface. Used to deliver Ethernet frames on the local network segment. |
| **Layer 2** | Local delivery on one network segment, using MAC addresses (Ethernet). |
| **Layer 3** | Delivery between networks, using IP addresses and routing. |
| **Switch** | The device network cables plug into. It forwards Ethernet frames between ports on the same local network. |
| **Default route / gateway** | Where the machine sends traffic for any network it has no specific route for — normally a router on the local segment. |
| **LACP** | Link Aggregation Control Protocol (IEEE 802.3ad). A standard by which a host and a switch agree which links form one aggregated group. |
| **Hash** | A function that turns fields such as source and destination IP into a number, used to pick which member link a given flow uses. |

## Bond terminology

A bonding configuration contains:

- A **bond interface**, such as `bond0`.
- Two or more **member interfaces**, such as `eth1` and `eth2`.
- A **bonding mode** that controls how the interfaces are used.
- A **link-monitoring method** that detects interface failures.

The bond interface is sometimes called the **master** interface. Its attached physical interfaces have traditionally been called **slaves**, but **member interfaces** is now the preferred term. Some kernel output still prints the word `Slave`.

IP addresses should normally be assigned to the bond interface rather than to its individual members.

Example:

```text
bond0: 192.168.1.50/24
├── eth1
└── eth2
```

Here `bond0` owns the IP address. The member interfaces carry traffic on behalf of the bond.

> [!TIP]
> **Try it — see the raw interfaces before any bond exists**
>
> ```sh
> ip -brief link show
> ```
>
> Expect something like:
>
> ```text
> lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
> enp0s1           UP             52:54:00:11:22:33 <BROADCAST,MULTICAST,UP,LOWER_UP>
> enp0s2           DOWN           52:54:00:aa:bb:cc <BROADCAST,MULTICAST>
> enp0s3           DOWN           52:54:00:dd:ee:ff <BROADCAST,MULTICAST>
> ```
>
> The interface names on your machine will differ. One interface carries your SSH session and has an IP — leave that one alone. The other two (here `enp0s2` and `enp0s3`) have no IP and no bond yet; those are the member interfaces you will bond together in the checkpoints below.

## Common bonding modes

Linux supports several bonding modes. The right one depends on whether the goal is failover, load distribution, or integration with a switch using LACP.

### Mode 1: Active-backup

Active-backup mode uses one interface for traffic while the other members wait as backups.

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

It does not combine the bandwidth of all members. If two 1 Gbit/s interfaces are bonded, the bond normally still provides up to 1 Gbit/s of active bandwidth.

Active-backup is often a good starting point when redundancy matters more than extra throughput.

> [!TIP]
> **Try it — build a temporary active-backup bond and inspect it**
>
> Replace `enp0s2` and `enp0s3` with the two non-SSH interface names you saw above. These commands only touch the spare member interfaces, so they will not drop your session — but never run them against the interface carrying your SSH connection.
>
> ```sh
> sudo ip link add bond0 type bond mode active-backup miimon 100
> sudo ip link set enp0s2 down
> sudo ip link set enp0s3 down
> sudo ip link set enp0s2 master bond0
> sudo ip link set enp0s3 master bond0
> sudo ip link set bond0 up
> sudo ip link set enp0s2 up
> sudo ip link set enp0s3 up
> cat /proc/net/bonding/bond0
> ```
>
> Expect something like:
>
> ```text
> Ethernet Channel Bonding Driver: v6.8.0
>
> Bonding Mode: fault-tolerance (active-backup)
> Currently Active Slave: enp0s2
> MII Status: up
> MII Polling Interval (ms): 100
>
> Slave Interface: enp0s2
> MII Status: up
> Link Failure Count: 0
> Permanent HW addr: 52:54:00:aa:bb:cc
>
> Slave Interface: enp0s3
> MII Status: up
> Link Failure Count: 0
> Permanent HW addr: 52:54:00:dd:ee:ff
> ```
>
> `Bonding Mode` confirms active-backup, and exactly one member is listed as `Currently Active Slave` — the other is standing by. `ip link show master bond0` lists the same two members from the interface side.

### Mode 5: Adaptive transmit load balancing

Adaptive transmit load balancing (`balance-tlb`) distributes *outgoing* traffic across the available members. Incoming traffic is normally received through one interface.

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

Because incoming and outgoing traffic are handled differently, the benefit depends on the traffic pattern. A single network connection should not be expected to use the combined bandwidth of all interfaces.

In the playground you can tear the bond down with `sudo ip link del bond0` and rebuild it with `mode balance-tlb` instead of `mode active-backup`; the `Bonding Mode` line in `/proc/net/bonding/bond0` changes to `transmit load balancing`.

### Mode 4: IEEE 802.3ad LACP

Mode 4 creates a dynamic link aggregation group using IEEE 802.3ad and LACP.

This mode is configured as:

```text
mode=4
```

or:

```text
mode=802.3ad
```

LACP lets the Linux machine and the switch negotiate which links belong to the aggregation group.

It can provide:

- Link redundancy.
- Distribution of traffic across multiple interfaces.
- Higher total throughput when multiple network flows are active.
- Detection and management of links within the aggregation group.

LACP requires matching configuration on both ends. The switch ports must belong to the same LACP aggregation group.

A single network flow normally uses only one physical interface, because traffic is placed on a member by hashing packet fields. Multiple simultaneous flows can land on different members. Two 1 Gbit/s links may therefore provide close to 2 Gbit/s across many flows, while a single transfer stays near 1 Gbit/s.

> Mode 4 cannot be exercised in this module's playground: its two extra segments are isolated Layer 2 networks with no LACP-capable switch on the other end, so no aggregation group can form. The active-backup checkpoints (mode 1) are used instead because they need nothing from the switch.

## Comparing common bonding modes

| Mode | Name | Primary purpose | Switch configuration | Uses multiple active links |
|---|---|---|---|---|
| `1` | `active-backup` | Redundancy and failover | Not normally required | No |
| `5` | `balance-tlb` | Outbound load distribution | Not normally required | For outgoing traffic |
| `4` | `802.3ad` | Link aggregation with LACP | Required | Yes |

## Link monitoring

A bond needs a way to detect whether a member interface is still working.

One common method is Media Independent Interface monitoring, or **MII monitoring**. The following setting checks the link state every 100 milliseconds:

```text
miimon=100
```

MII monitoring can detect conditions such as:

- A disconnected network cable.
- A disabled switch port.
- A failed physical interface.
- Loss of the local Ethernet carrier.

MII monitoring only checks the *local* link state. It does not confirm that the default gateway or a remote service is reachable. The link can stay "up" even if a router farther upstream has failed. This is the difference between **link state** (is this cable electrically alive?) and **end-to-end reachability** (can I actually reach the other host?).

> [!TIP]
> **Try it — force a failover and watch MII monitoring react**
>
> With the active-backup bond from earlier still up, take the *currently active* member down. Use the member name shown as `Currently Active Slave`, not your SSH interface:
>
> ```sh
> sudo ip link set enp0s2 down
> cat /proc/net/bonding/bond0
> ```
>
> Expect something like:
>
> ```text
> Bonding Mode: fault-tolerance (active-backup)
> Currently Active Slave: enp0s3
> MII Status: up
>
> Slave Interface: enp0s2
> MII Status: down
> Link Failure Count: 1
>
> Slave Interface: enp0s3
> MII Status: up
> Link Failure Count: 0
> ```
>
> Within about 100 ms of the link dropping, `MII Status` for that member flips to `down`, its `Link Failure Count` increments, and `Currently Active Slave` moves to the other member. Bring it back with `sudo ip link set enp0s2 up`. Interface names, MACs, and counts are examples.

## Creating a temporary bond

The `ip` command can create a bond directly in the running system:

```bash
sudo ip link add name bond0 type bond mode active-backup miimon 100
```

This creates:

- A bond named `bond0`.
- An active-backup configuration.
- MII link monitoring every 100 milliseconds.

This configuration is temporary. It is normally lost when the machine restarts.

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

Enable the bond and its members:

```bash
sudo ip link set bond0 up
sudo ip link set eth1 up
sudo ip link set eth2 up
```

**Warning:** these commands can interrupt network connectivity. Do not modify the interface used for your current SSH session unless you have console access or another recovery method. In the playground, that means only ever touching the two spare member NICs, never the management interface.

## Assigning an IP address to the bond

An IP address should normally be assigned to the bond, not to its members:

```bash
sudo ip addr add 192.168.1.50/24 dev bond0
```

If the machine needs to reach other networks, it may also need a default route:

```bash
sudo ip route add default via 192.168.1.1 dev bond0
```

Replace the example values with addresses appropriate for the local network.

Member interfaces should normally not keep their own Layer 3 addresses after joining the bond. The bond becomes the logical Layer 3 interface used by the operating system.

> [!TIP]
> **Try it — give the bond an address**
>
> The playground's spare NICs sit on the `192.168.50.0/24` and `192.168.51.0/24` segments, so pick an address in one of those ranges:
>
> ```sh
> sudo ip addr add 192.168.50.50/24 dev bond0
> ip addr show dev bond0
> ```
>
> Expect something like:
>
> ```text
> 5: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 ...
>     inet 192.168.50.50/24 scope global bond0
>        valid_lft forever preferred_lft forever
> ```
>
> The address lands on `bond0`, not on `enp0s2` or `enp0s3`. The members stay at Layer 2 and carry the traffic; the bond is the interface the OS routes through. Remove it again with `sudo ip addr del 192.168.50.50/24 dev bond0`. The interface index (`5:`) and names are examples.

## Inspecting a bond

Show the bond interface:

```bash
ip link show bond0
```

Show its assigned addresses:

```bash
ip addr show dev bond0
```

Show the attached members:

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

Important fields:

- `Bonding Mode` — the mode the bond is running.
- `MII Status` — whether the bond currently detects a working link.
- `MII Polling Interval` — how often the link state is checked.
- `Currently Active Slave` — the member currently carrying traffic in active-backup mode.
- `Link Failure Count` — how many failures have been detected for a member.
- `Permanent HW addr` — the original MAC address of a member interface.

The kernel still uses the historical word `Slave` in some output, even though the interfaces can be described as bond members in documentation.

## Temporary and persistent configuration

A bond created with the `ip` command is **runtime** configuration. It normally disappears after a restart.

A persistent bond should be configured through the network-management system your distribution provides, such as:

- NetworkManager.
- Netplan.
- `systemd-networkd`.
- `ifupdown`.
- Distribution-specific network configuration files.

Do not configure the same interfaces through more than one network-management system at once. Conflicting configurations can make interfaces change state unexpectedly.

> [!TIP]
> **Try it — confirm the runtime bond does not survive a reboot**
>
> This one restarts the whole VM, so it will drop your SSH session for a minute. That is safe in a throwaway playground; reconnect afterwards with `astrona ssh linux-bonding-playground`.
>
> ```sh
> sudo reboot
> ```
>
> After reconnecting:
>
> ```sh
> cat /proc/net/bonding/bond0
> ```
>
> Expect:
>
> ```text
> cat: /proc/net/bonding/bond0: No such file or directory
> ```
>
> The bonding *driver* is still loaded (the playground's bootstrap arranges that), but `bond0` and everything you built with `ip` is gone. Anything that must come back after a reboot has to be written into one of the network-management systems listed above.

## High-availability considerations

Bonding protects against certain failures, but it does not remove every single point of failure.

For meaningful redundancy, consider whether the member interfaces use:

- Different physical network cards.
- Different cables.
- Different switch ports.
- Different switches.
- Independent power sources.
- Independent upstream network paths.

Connecting both interfaces to the same switch protects against a cable or port failure, but not against failure of the whole switch.

When members connect to different switches, the switches must support the chosen design. Multi-switch LACP normally requires technologies such as switch stacking, MLAG, or an equivalent vendor-specific feature.
