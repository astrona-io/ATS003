# One Link From Many Antennas

Astronaut, in this part you team two antennas into one. A bond takes several network interfaces and presents them as a single interface, normally called `bond0`. You first look at the parts a bond is made of, then build one in your playground and read its state straight from the kernel.

## What a bond gives you

A machine with two physical interfaces, `eth1` and `eth2`, can combine them into a single `bond0`. Depending on the **bonding mode**, the policy that decides how the members are used, that can give you:

- **redundancy:** more than one interface can do the job, so one can fail without an outage;
- **automatic failover:** traffic moves to a working member when the active one fails;
- **traffic distribution:** outgoing (and sometimes incoming) traffic is spread across members;
- **higher total throughput:** more combined capacity across several links.

Bonding does not guarantee high availability on its own. What you really get depends on the mode, the switch configuration, the cabling, the network beyond the switch, and whether failures are noticed at all.

## Key terms

These words come up in every part of this module. Keep the table close until they feel normal.

| Term | Meaning in this module |
|---|---|
| **Member interface** | A physical (or virtual) network interface attached to a bond: one antenna in the team. The older word is *slave*; some kernel output still prints `Slave`. |
| **Bond / master interface** | The logical interface (`bond0`) the operating system uses. It owns the IP address. |
| **Bonding mode** | The policy that decides how members are used: failover only, load distribution, or LACP. |
| **MII monitoring** | Media Independent Interface monitoring: the bond checks each member's local link state on a fixed interval. |
| **LACP** | Link Aggregation Control Protocol (IEEE 802.3ad): the host and the switch agree which links form one group. |
| **Hash** | A function that turns fields such as source and destination IP address into a number. The bond uses it to pick which member carries a given flow. |

## Anatomy of a bond

A bond has four pieces, and the address sits on only one of them. This section names the pieces before you build them.

### The four pieces

A bonding configuration has:

- a **bond interface**, such as `bond0`;
- two or more **member interfaces**, such as `eth1` and `eth2`;
- a **bonding mode** that controls how the members are used;
- a **link-monitoring method** that notices when a member fails.

The bond interface is sometimes called the **master**. Its attached interfaces were traditionally called **slaves** and are now called **member interfaces**. Some kernel output still prints `Slave`.

### Where the address goes

The IP address, the ship's call sign, goes on the bond, not on a member:

```text
bond0: 192.168.1.50/24
├── eth1
└── eth2
```

`bond0` owns the address. `eth1` and `eth2` carry traffic for it at Layer 2, the level of local delivery by MAC address (the serial number stamped on each antenna).

### See it in your playground

<!-- astrona:playground:renew -->

Before you build anything, list the raw interfaces:

```sh
ip -brief link show
```

Expect something like:

```text
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
enp0s1           UP             52:54:00:11:22:33 <BROADCAST,MULTICAST,UP,LOWER_UP>
enp0s2           DOWN           52:54:00:aa:bb:cc <BROADCAST,MULTICAST>
enp0s3           DOWN           52:54:00:dd:ee:ff <BROADCAST,MULTICAST>
```

Interface names on your machine will be different. One interface carries your SSH session and has an IP address: leave that one alone. The other two (here `enp0s2` and `enp0s3`) are `DOWN`, have no address, and are in no bond yet. Those are the members you bond together next.

## Building a bond with `ip`

The `ip link` command both creates the bond and attaches the members. Two verbs do the work: `add` makes a new virtual interface of a given `type`, and `set … master` moves an existing interface into it.

### Create the bond

This one line creates `bond0`, sets the mode to active-backup, and turns on link monitoring every 100 milliseconds:

```bash
sudo ip link add bond0 type bond mode active-backup miimon 100
```

### Attach the members

Next, the kernel needs each member brought down, moved into the bond, and then the bond and members brought up:

```bash
sudo ip link set enp0s2 down
sudo ip link set enp0s3 down
sudo ip link set enp0s2 master bond0
sudo ip link set enp0s3 master bond0
sudo ip link set bond0 up
sudo ip link set enp0s2 up
sudo ip link set enp0s3 up
```

A member has to be `DOWN` before `master` accepts it: the kernel will not move a live interface into a bond. Everything here is **runtime** state, chalked on the console, so a reboot clears it.

`ip link set … down`, `master` and `up` change the kernel's network state and can cut your connection. Only ever run them against the two spare member interfaces, never against the interface that carries your SSH session.

### The bond's state file

The kernel shows the bond's live state as a file, `/proc/net/bonding/bond0`. It is not a real file on disk: the kernel writes it fresh each time you read it. So `cat` prints the current mode, the polling interval, which member is active, and one block per member with its `MII Status` and `Link Failure Count`.

### See it in your playground

Build a temporary active-backup bond and read its state. Replace `enp0s2` and `enp0s3` with the two spare interface names from your own listing:

```sh
sudo ip link add bond0 type bond mode active-backup miimon 100
sudo ip link set enp0s2 down
sudo ip link set enp0s3 down
sudo ip link set enp0s2 master bond0
sudo ip link set enp0s3 master bond0
sudo ip link set bond0 up
sudo ip link set enp0s2 up
sudo ip link set enp0s3 up
cat /proc/net/bonding/bond0
```

Expect something like:

```text
Ethernet Channel Bonding Driver: v6.8.0

Bonding Mode: fault-tolerance (active-backup)
Currently Active Slave: enp0s2
MII Status: up
MII Polling Interval (ms): 100

Slave Interface: enp0s2
MII Status: up
Link Failure Count: 0
Permanent HW addr: 52:54:00:aa:bb:cc

Slave Interface: enp0s3
MII Status: up
Link Failure Count: 0
Permanent HW addr: 52:54:00:dd:ee:ff
```

`Bonding Mode` confirms active-backup. Exactly one member is listed as `Currently Active Slave`; the other one waits. `ip link show master bond0` lists the same two members from the interface side. The names, hardware addresses and driver version here are examples.

> [!TIP]
> Make `cat /proc/net/bonding/bond0` your first check whenever a bond behaves oddly. It shows what the kernel is really doing, not what a configuration file says it should do.

## Common pitfalls

> [!WARNING]
> - **Putting the IP address on a member instead of `bond0`.** The address, and any route, belong on the bond. A member that keeps its own Layer 3 address after joining causes confusing paths.
> - **Enslaving a live interface.** `ip link set <dev> master bond0` needs `<dev>` to be `DOWN` first. Bring it down, attach it, then bring it and the bond up.
> - **Touching the management interface.** Bonding the interface that carries your SSH session cuts your link to the ship. Use only the spare interfaces.
