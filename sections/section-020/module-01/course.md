# Link Aggregation with Linux Bonding

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-020/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-01/playground
> astrona destroy linux-bonding-playground
> ```

Linux **bonding** takes several network interfaces and presents them to the rest of the system as one. The combined interface is normally called `bond0`. It is a *logical* interface — kernel software on top of real network cards, not a physical port you can plug a cable into. Applications and services then use `bond0` and never touch the member cards directly.

For example, a machine with two physical interfaces `eth1` and `eth2` can combine them into a single `bond0`. Depending on the **bonding mode**, that can give you:

- **redundancy** — more than one interface can do the job, so one can fail without an outage;
- **automatic failover** — traffic moves to a working member when the active one fails;
- **traffic distribution** — outgoing (and sometimes incoming) traffic spread across members;
- **higher total throughput** — more combined capacity across several links.

Bonding does not guarantee high availability on its own. What you actually get depends on the mode, the switch configuration, the cabling, the upstream network design, and whether failures are detected at all.

## Learning objectives

After this module you can:

- Explain what a Linux bond is, why an IP address belongs on `bond0` rather than on its members, and what "member interface" means.
- Build a temporary active-backup bond with `ip link` and read its state from `/proc/net/bonding/bond0`.
- Compare the common bonding modes — active-backup (1), balance-tlb (5), and 802.3ad/LACP (4) — by purpose, switch requirement, and whether more than one link carries traffic at once.
- Configure MII link monitoring with `miimon` and state what it detects and what it does not.
- Trigger a failover by taking the active member down and identify the new `Currently Active Slave`.
- Explain why an `ip`-created bond is lost on reboot and name the systems that make one persistent.

## Before you start

This module assumes you can open a shell, run commands with `sudo`, and have seen interface names like `enp0s2` and a dotted IPv4 address with a prefix such as `192.168.50.50/24`. MAC address, Layer 2 and Layer 3, switch, LACP, and hash are all defined as they come up. Familiarity with `ip link` and `ip addr` from the interfaces module helps but is not assumed.

Open a shell on the playground VM with `astrona ssh astro-linux-bonding-playground`. The machine has three usable interfaces: one management NIC that carries your SSH session and holds an address — leave it alone — and two spare NICs, `DOWN` and address-less, on isolated `192.168.50.0/24` and `192.168.51.0/24` segments. Those two are the bond members for every checkpoint. The bonding driver is preloaded, but no `bond0` exists yet — you build it. The isolated segments have no LACP-capable switch, so mode 4 cannot be built here; the checkpoints use active-backup (mode 1), which needs nothing from the switch.

## Where this fits

This section covers three ways Linux joins interfaces, and they solve different problems. **Bonding** (here) makes several NICs act as one link, for redundancy or extra capacity. A **bridge** (next module) is a virtual Layer 2 switch that connects separate segments and virtual machines. **Static routing** (module 3) is Layer 3 — choosing which interface a packet leaves by. A bond sits below all of that: whatever you build on top — an address, a bridge port, a route — attaches to `bond0`, and the members just carry frames.

## Key terms

| Term | Meaning in this module |
|---|---|
| **Member interface** | A physical (or virtual) NIC attached to a bond. Older term: *slave*; some kernel output still prints `Slave`. |
| **Bond / master interface** | The logical interface (`bond0`) the OS uses; it owns the IP address. |
| **Bonding mode** | The policy controlling how members are used — failover only, or load distribution, or LACP. |
| **MII monitoring** | Media Independent Interface monitoring — the bond polling each member's local link state on an interval. |
| **LACP** | Link Aggregation Control Protocol (IEEE 802.3ad) — a host and switch agreeing which links form one aggregated group. |
| **Hash** | A function turning fields such as source/destination IP into a number, used to pick which member a given flow uses. |

## Anatomy of a bond

A bonding configuration has four parts:

- a **bond interface**, such as `bond0`;
- two or more **member interfaces**, such as `eth1` and `eth2`;
- a **bonding mode** that controls how the members are used;
- a **link-monitoring method** that detects member failures.

The bond interface is sometimes called the **master**; its attached NICs were traditionally called **slaves**, now **member interfaces**. Some kernel output still prints `Slave`.

The IP address goes on the bond, not on a member:

```text
bond0: 192.168.1.50/24
├── eth1
└── eth2
```

`bond0` owns the address; `eth1` and `eth2` carry traffic on its behalf at Layer 2.

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
> Interface names on your machine will differ. One interface carries your SSH session and has an IP — leave that one alone. The other two (here `enp0s2` and `enp0s3`) are `DOWN`, address-less, and in no bond yet; those are the members you will bond together below.

## Building a bond with `ip`

The `ip link` subcommand both creates the bond and attaches members. Two verbs do the work: `add` makes a new virtual interface of a given `type`, and `set … master` moves an existing interface into it.

```bash
sudo ip link add bond0 type bond mode active-backup miimon 100
```

That one line creates `bond0`, sets the mode to active-backup, and turns on MII monitoring every 100 ms. Then each member is brought down, moved into the bond, and the bond and members are brought up:

```bash
sudo ip link set enp0s2 down
sudo ip link set enp0s3 down
sudo ip link set enp0s2 master bond0
sudo ip link set enp0s3 master bond0
sudo ip link set bond0 up
sudo ip link set enp0s2 up
sudo ip link set enp0s3 up
```

A member has to be `DOWN` before `master` will accept it — the kernel will not move a live interface into a bond. Everything here is **runtime** state; a reboot clears it.

The bond's live state is exposed as a file, `/proc/net/bonding/bond0`. It is not a real disk file — the kernel generates it on read — so `cat` prints the current mode, the polling interval, which member is active, and a per-member block with `MII Status` and `Link Failure Count`.

> [!WARNING]
> `ip link set … down`, `master`, and `up` change kernel network state and can cut connectivity. Only ever run them against the two spare member NICs, never the interface carrying your SSH session.

> [!TIP]
> **Try it — build a temporary active-backup bond and inspect it**
>
> Replace `enp0s2` / `enp0s3` with the two non-SSH interface names from the previous checkpoint.
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
> `Bonding Mode` confirms active-backup, and exactly one member is listed as `Currently Active Slave` — the other stands by. `ip link show master bond0` lists the same two members from the interface side. Names, MACs, and the driver version are examples.

## Bonding modes

The right mode depends on whether the goal is failover, outbound load distribution, or LACP integration with a switch.

### Mode 1 — active-backup

One member carries traffic; the rest wait as backups. If the active member fails, another takes over. Configured as `mode=1` or `mode=active-backup`. It needs nothing from the switch and works with almost any of them, but it does **not** add bandwidth — two 1 Gbit/s members still give up to 1 Gbit/s. A good default when redundancy matters more than throughput.

### Mode 5 — balance-tlb (adaptive transmit load balancing)

*Outgoing* traffic is spread across the members; incoming traffic normally arrives on one. Configured as `mode=5` or `mode=balance-tlb`. Also needs nothing from the switch. The benefit depends on the traffic pattern, and a single connection still will not exceed one member's bandwidth. In the playground you can `sudo ip link del bond0` and rebuild with `mode balance-tlb`; the `Bonding Mode` line then reads `transmit load balancing`.

### Mode 4 — 802.3ad / LACP

A dynamic aggregation group negotiated with the switch via LACP. Configured as `mode=4` or `mode=802.3ad`. It can give redundancy, traffic distribution across members, and higher total throughput when many flows are active — a single flow still stays on one member, because traffic is placed by hashing packet fields. Both ends must be configured to match: the switch ports have to be in the same LACP group.

> Mode 4 cannot be exercised in this playground. Its two extra segments are isolated Layer 2 networks with no LACP-capable switch on the other end, so no aggregation group can form. The active-backup checkpoints (mode 1) are used because they need nothing from the switch.

| Mode | Name | Primary purpose | Switch config | Multiple active links |
|---|---|---|---|---|
| `1` | `active-backup` | Redundancy and failover | Not normally required | No |
| `5` | `balance-tlb` | Outbound load distribution | Not normally required | For outgoing traffic |
| `4` | `802.3ad` | Link aggregation with LACP | Required | Yes |

## Link monitoring with `miimon`

A bond needs a way to tell whether a member is still working. The common method is **MII monitoring** — Media Independent Interface monitoring. `miimon=100` polls each member's link state every 100 ms.

It detects local link problems: a disconnected cable, a disabled switch port, a failed NIC, loss of the local Ethernet carrier. It does **not** confirm that the default gateway or a remote service is reachable — the link can read "up" while a router farther upstream has failed. That is the difference between **link state** (is this cable electrically alive?) and **end-to-end reachability** (can I actually reach the other host?).

> [!TIP]
> **Try it — force a failover and watch MII monitoring react**
>
> With the active-backup bond still up, take the *currently active* member down — use the name shown as `Currently Active Slave`, not your SSH interface:
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
> Within about 100 ms of the link dropping, that member's `MII Status` flips to `down`, its `Link Failure Count` increments, and `Currently Active Slave` moves to the other member. Bring it back with `sudo ip link set enp0s2 up`. Names and counts are examples.

## The bond's IP address

The IP address goes on `bond0`, and so does any default route the machine needs:

```bash
sudo ip addr add 192.168.1.50/24 dev bond0
sudo ip route add default via 192.168.1.1 dev bond0
```

Members should not keep their own Layer 3 addresses after joining — the bond is the logical Layer 3 interface the OS routes through.

> [!TIP]
> **Try it — give the bond an address**
>
> The spare NICs sit on `192.168.50.0/24` and `192.168.51.0/24`, so pick an address in one range:
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
> The address lands on `bond0`, not on `enp0s2` or `enp0s3`. The members stay at Layer 2 and carry the traffic; the bond is what the OS routes through. Remove it with `sudo ip addr del 192.168.50.50/24 dev bond0`. The interface index (`5:`) and names are examples.

## Reading a bond's state

Four commands cover inspection:

- `ip link show bond0` — the bond interface and its flags (`MASTER` marks it as owning members).
- `ip addr show dev bond0` — the addresses on it.
- `ip link show master bond0` — the attached members, from the interface side.
- `cat /proc/net/bonding/bond0` — the full picture: `Bonding Mode`, `MII Status`, `MII Polling Interval`, `Currently Active Slave`, and per-member `Link Failure Count` and `Permanent HW addr` (a member's original MAC).

## Runtime versus persistent configuration

A bond built with `ip` is **runtime** configuration — normally gone after a restart. A persistent bond is defined through the distribution's network-management system: NetworkManager, Netplan, `systemd-networkd`, `ifupdown`, or distribution-specific files. Do not configure the same interfaces through more than one such system — conflicting configurations make interfaces change state unexpectedly.

> [!TIP]
> **Try it — confirm the runtime bond does not survive a reboot**
>
> This restarts the whole VM and drops your SSH session for about a minute; reconnect with `astrona ssh astro-linux-bonding-playground`.
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
> The bonding *driver* is still loaded (the playground's bootstrap arranges that), but `bond0` and everything you built with `ip` is gone. Anything that must return after a reboot has to be written into one of the network-management systems above.

## High-availability considerations

Bonding removes some single points of failure, not all. For meaningful redundancy, check whether the members use different physical NICs, different cables, different switch ports, different switches, independent power, and independent upstream paths. Two members into the *same* switch survive a cable or port fault but not the switch itself. Members split across two switches need a design the switches support — stacking, MLAG, or an equivalent.

> [!WARNING]
> **Common pitfalls**
>
> - **Putting the IP on a member instead of `bond0`.** The address, and any route, belong on the bond. A member with its own Layer 3 address after joining causes confusing paths.
> - **Expecting active-backup to add bandwidth.** Mode 1 gives one active link at a time. Bonding two 1 Gbit/s NICs in mode 1 still caps at ~1 Gbit/s. Use mode 4 or 5 for distribution, and even then a single flow stays on one member.
> - **Reading `MII Status: up` as "the network works".** MII monitoring checks the local link only. The gateway or a remote host can still be unreachable with every member `up`.
> - **Building mode 4 against an unconfigured switch.** LACP needs matching switch-side configuration; without it the group never forms. Mode 1 needs nothing from the switch.
> - **Enslaving a live interface.** `ip link set <dev> master bond0` needs `<dev>` to be `DOWN` first. Bring it down, enslave it, then bring it and the bond up.
> - **Both members into one switch and calling it redundant.** That covers a port or cable fault, not a switch failure or an upstream path failure.
