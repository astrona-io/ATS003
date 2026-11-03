# Bonding Modes And Failover

Astronaut, a team of antennas needs a plan. Should one antenna talk while the other waits, or should both talk at once? That plan is the **bonding mode**. In this part you compare the three modes you meet most often, learn how the bond notices a broken link, and then break one on purpose to watch the backup take over.

## Bonding modes

The right mode depends on your goal: failover only, spreading outgoing traffic, or a full link group agreed with the switch. Each mode below has a number and a name; the kernel accepts either.

### Mode 1: active-backup

One member carries traffic; the rest wait as backups. If the active member fails, another one takes over. You set it as `mode=1` or `mode=active-backup`.

It needs nothing from the switch and works with almost any switch. It does **not** add bandwidth: two 1 Gbit/s members still give up to 1 Gbit/s. It is a good default when redundancy matters more than speed.

### Mode 5: balance-tlb

The name means adaptive transmit load balancing. *Outgoing* traffic is spread across the members; incoming traffic normally arrives on one. You set it as `mode=5` or `mode=balance-tlb`.

It also needs nothing from the switch. How much it helps depends on the traffic, and a single connection still cannot go faster than one member. In the playground you can run `sudo ip link del bond0` and rebuild the bond with `mode balance-tlb`; the `Bonding Mode` line then reads `transmit load balancing`.

### Mode 4: 802.3ad with LACP

The host and the switch agree on a group of links using LACP (Link Aggregation Control Protocol). You set it as `mode=4` or `mode=802.3ad`.

It can give redundancy, traffic spread across members, and more total throughput when many flows are active. A single flow still stays on one member, because the bond places traffic by hashing packet fields. Both ends must match: the switch ports have to be in the same LACP group.

Mode 4 cannot be tried in this playground. Its two extra segments are isolated Layer 2 networks with no LACP switch on the other end, so no group can form. That is why the hands-on steps use mode 1.

### The modes side by side

| Mode | Name | Primary purpose | Switch configuration | Multiple active links |
|---|---|---|---|---|
| `1` | `active-backup` | Redundancy and failover | Not normally required | No |
| `5` | `balance-tlb` | Outbound load distribution | Not normally required | For outgoing traffic |
| `4` | `802.3ad` | Link aggregation with LACP | Required | Yes |

## Link monitoring with `miimon`

A bond needs a way to tell whether a member still works. The common method is MII monitoring (Media Independent Interface monitoring). This section shows what it checks, and what it cannot see.

### What it checks

`miimon=100` makes the bond check each member's link state every 100 milliseconds. It notices local link problems: a pulled cable, a disabled switch port, a failed network card, or a lost Ethernet carrier.

It does **not** check that the default gateway or a far-away service can be reached. The link can read "up" while a router further along has failed. That is the difference between **link state** (is this antenna picking up a carrier?) and **end-to-end reachability** (can my signal really reach the other ship?).

### See it in your playground

<!-- astrona:playground:renew -->

You need an active-backup bond over the two spare interfaces. If you do not have one, build it: `sudo ip link add bond0 type bond mode active-backup miimon 100`, then set both members down, attach each with `master bond0`, and bring the bond and both members up.

Now take the *currently active* member down. Use the name shown as `Currently Active Slave`, not your SSH interface:

```sh
sudo ip link set enp0s2 down
cat /proc/net/bonding/bond0
```

Expect something like:

```text
Bonding Mode: fault-tolerance (active-backup)
Currently Active Slave: enp0s3
MII Status: up

Slave Interface: enp0s2
MII Status: down
Link Failure Count: 1

Slave Interface: enp0s3
MII Status: up
Link Failure Count: 0
```

Within about 100 milliseconds of the link dropping, the bonding driver marks that member's `MII Status` as `down`, adds one to its `Link Failure Count`, and moves `Currently Active Slave` to the other member. Bring the member back with `sudo ip link set enp0s2 up`. The names and counts are examples.

## The bond's IP address

The address belongs on `bond0`, and so does any default route the machine needs. This section shows the commands and lets you see where the address lands.

### Address and route on the bond

```bash
sudo ip addr add 192.168.1.50/24 dev bond0
sudo ip route add default via 192.168.1.1 dev bond0
```

Members should not keep their own Layer 3 addresses after they join. The bond is the one logical interface the operating system routes through.

### See it in your playground

The spare interfaces sit on `192.168.50.0/24` and `192.168.51.0/24`, so pick an address in one of those ranges:

```sh
sudo ip addr add 192.168.50.50/24 dev bond0
ip addr show dev bond0
```

Expect something like:

```text
5: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 ...
    inet 192.168.50.50/24 scope global bond0
       valid_lft forever preferred_lft forever
```

The address lands on `bond0`, not on `enp0s2` or `enp0s3`. The members stay at Layer 2 and carry the traffic; the bond is what the operating system routes through. Remove it with `sudo ip addr del 192.168.50.50/24 dev bond0`. The interface index (`5:`) and the names are examples.

## Reading a bond's state

Four commands cover all your checks on a bond. Keep this list handy for the exam:

- `ip link show bond0`: the bond interface and its flags (`MASTER` marks it as the owner of members).
- `ip addr show dev bond0`: the addresses on it.
- `ip link show master bond0`: the attached members, seen from the interface side.
- `cat /proc/net/bonding/bond0`: the full picture. It shows `Bonding Mode`, `MII Status`, `MII Polling Interval`, `Currently Active Slave`, and for each member its `Link Failure Count` and `Permanent HW addr` (the member's original hardware address).

## Common pitfalls

> [!WARNING]
> - **Expecting active-backup to add bandwidth.** Mode 1 gives one active link at a time. Two 1 Gbit/s interfaces in mode 1 still top out at about 1 Gbit/s. Use mode 4 or 5 to spread traffic, and even then a single flow stays on one member.
> - **Reading `MII Status: up` as "the network works".** MII monitoring checks the local link only. The gateway or a remote host can still be out of reach while every member is `up`.
> - **Building mode 4 against a switch that is not set up for it.** LACP needs matching configuration on the switch; without it the group never forms. Mode 1 needs nothing from the switch.
> - **Taking down the wrong member.** For a failover test, take down the member named in `Currently Active Slave`, and never the interface that carries your SSH session.
