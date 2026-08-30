# Network Interfaces and IPv4 & IPv6 Addressing

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-010/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-01/playground
> astrona destroy network-interfaces-playground
> ```

Every packet a Linux machine sends or receives passes through a **network interface** — a connection point between the operating system and a network. Most interfaces also carry one or more **IP addresses**, the labels other machines use to send traffic to this one. This module is about reading both on a live machine: which interfaces exist, what state each is in, which addresses are bound to it, and why an address you set by hand disappears on the next reboot.

An interface can be:

- a physical network card — an Ethernet or Wi-Fi adapter;
- a virtual interface from a virtual machine, container platform, VPN, or bridge;
- the **loopback** interface, which the machine uses to talk to itself.

Linux names interfaces `eth0`, `ens18`, `enp1s0`, `wlan0`, and so on. The name is a label the kernel assigns; it does not by itself decide what the interface can do.

> As an analogy: the interface is a doorway between the OS and a network, and an IP address is the number written on that doorway so traffic can find it. One doorway can carry several numbers, or none. The analogy breaks the moment routing enters — a doorway does not choose which other doorway a letter travels to next; the routing table does.

## Learning objectives

After this module you can:

- List the network interfaces on a Linux machine and read each one's state, MAC address, and MTU with `ip link show`.
- Explain what an IPv4 address, an IPv6 address, and a prefix length (`/24`, `/64`) each describe, and decide whether two addresses sit on the same local network.
- Show the IPv4 and IPv6 addresses bound to each interface with `ip addr show`, including an interface that has none.
- Distinguish *enabled* (UP), *connected* (LOWER_UP), and *reachable*, and name which command reports which.
- Read a routing table with `ip route show` and identify the default gateway.
- Explain why a change made with `ip addr add` or `ip link set` is gone after a reboot, and name the systems that make addressing persistent.

## Before you start

This module assumes you can open a shell and run commands, and that you have seen a dotted IPv4 address such as `192.168.1.10`. No networking theory is assumed — Layer 3, prefix length, gateway, and MAC address are each defined as they come up.

The playground callout above brings the VM up; open a shell on it with `astrona ssh astro-network-interfaces-playground`. The machine has four interfaces already in place: the loopback `lo`; one **management interface** that carries your SSH session and has a real address and a default route; and two spare NICs on isolated segments — one given an IPv4 and an IPv6 address, one deliberately left with none. Every inspection command below works as-is. The few state-changing commands are flagged, and are safe **only** on the two spare NICs.

## Where this fits

Interfaces and addressing are the layer everything else in Linux networking stands on. Routing picks which interface a packet leaves by, choosing among the addresses and prefixes configured here. Name resolution (DNS) hands back the same kind of address you bind to an interface. Every service that listens on a port binds to one of these addresses or to all of them at once. When a later problem shows up as "the service is unreachable," the first cuts you make are the distinctions in this module: is the interface up, does it have an address, is there a route.

## Key terms

| Term | Meaning in this module |
|---|---|
| **Network interface** | A physical or virtual connection point between the OS and a network, such as `enp0s1` or `lo`. |
| **Loopback** | The virtual interface `lo` a machine uses to talk to itself; always present, normally `127.0.0.1/8` and `::1/128`. |
| **IP address** | The address other hosts use to send Layer 3 traffic to this machine, in IPv4 or IPv6 form. |
| **Prefix length** | The `/24` or `/64` after an address; how many leading bits are the network part. |
| **UP** | Kernel state meaning the interface is administratively enabled. It implies nothing about an address or a working link. |
| **MAC address** | The hardware address of an interface, used to deliver frames on the local network segment. |
| **MTU** | Maximum Transmission Unit — the largest packet the interface sends in one piece. |
| **Default gateway** | The router a machine sends traffic to when it has no more specific route for the destination. |

## The `ip` command

One command runs through this whole module: `ip`, from the `iproute2` package. It has three subcommands you will use here, one per layer of the problem:

| Subcommand | Layer | Question it answers |
|---|---|---|
| `ip link` | the interface itself (Layer 2) | Is it switched on? What are its MAC address and MTU? |
| `ip addr` | addresses on the interface (Layer 3) | Which IPv4 / IPv6 addresses are bound to it? |
| `ip route` | the routing table | Where does traffic for a given destination go? |

Memory hook: **link** is the wire, **addr** is the label on the wire, **route** is the map. Each subcommand takes `show` to read state (safe, no privilege needed) and `add` / `del` / `set` to change it (needs `sudo`). Adding `-brief` (`-br`) to a `show` prints one aligned line per interface instead of the multi-line default.

## Listing the interfaces

`ip link show` lists every interface the kernel knows about and, for each: the name; whether it is administratively enabled (`UP`) or not (`DOWN`); whether a carrier is detected (`LOWER_UP`); the **MAC address** — the hardware address used to deliver frames one hop at a time on the local segment, underneath IP; and the **MTU**, the largest packet in bytes the interface sends in one piece (`1500` is the Ethernet default). The loopback's MAC is all zeros because it never puts a frame on a wire.

> [!TIP]
> **Try it — list this machine's interfaces**
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
> enp0s2           UP             52:54:00:aa:bb:cc <BROADCAST,MULTICAST,UP,LOWER_UP>
> enp0s3           UP             52:54:00:dd:ee:ff <BROADCAST,MULTICAST,UP,LOWER_UP>
> ```
>
> Four interfaces: loopback `lo`, the management interface carrying your SSH session, and the two spare NICs the playground added. Names and MAC addresses vary between runs. All three real interfaces read `UP` — yet one of them, as the next section shows, has no IP address at all.

## Does every interface need an IP address?

No. An interface can be enabled with no address on it. But an interface normally needs an address before it can exchange **Layer 3** traffic — packets moved between networks by IP address — with any other host.

A single interface can carry:

- no IP address;
- one IPv4 or one IPv6 address;
- several IPv4 and IPv6 addresses at once.

Linux calls an enabled interface **UP**. `UP` is only the administrative state — the OS has switched the interface on. It does not mean the interface has an address, that a cable is attached, or that anything is reachable through it.

`ip addr show` lists the addresses bound to each interface (it also repeats the link information from `ip link show`). `ip addr show dev enp0s2` narrows it to one interface.

> [!TIP]
> **Try it — the addresses, including the interface that has none**
>
> ```sh
> ip -brief addr show
> ```
>
> Expect something like:
>
> ```text
> lo               UNKNOWN        127.0.0.1/8 ::1/128
> enp0s1           UP             10.0.0.20/24
> enp0s2           UP             192.168.50.10/24 2001:db8:50::10/64
> enp0s3           UP
> ```
>
> `enp0s2` holds one IPv4 and one IPv6 address at once, each with its own prefix length (`/24` and `/64`). `enp0s3` is `UP` with an empty address column — enabled, no routable IP, unreachable at Layer 3. `lo` shows the standard loopback pair `127.0.0.1/8` and `::1/128`. Addresses and interface names vary; you may also see an `fe80::` link-local line on the IPv6-capable interfaces.

To see why one interface differs from another, inspect them one at a time. `ip link show dev <name>` answers a link-layer question — is it on, is there a carrier, what are its MAC address and MTU. `ip addr show dev <name>` answers a separate question — which addresses are bound to it. An interface can pass the first check and have nothing to show for the second.

> [!TIP]
> **Try it — an interface that is UP but has no address**
>
> Use the name of the empty-address interface from the previous checkpoint (the examples call it `enp0s3`):
>
> ```sh
> ip link show dev enp0s3
> ip addr show dev enp0s3
> ```
>
> Expect something like:
>
> ```text
> 4: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
>     link/ether 52:54:00:dd:ee:ff brd ff:ff:ff:ff:ff:ff
> ```
>
> `ip link show` reports `state UP` with a MAC address and an MTU — the interface is switched on. `ip addr show` for the same interface prints no routable `inet` or `inet6` line. (An `inet6 fe80::…` link-local line may still appear; see below.) That gap is the point: `UP` is an administrative state, not a guarantee of a usable address or of reachability.

## Reading an address: IPv4, IPv6, and the prefix length

**An IPv4 address** is 32 bits, written as four decimal numbers `0`–`255` separated by dots:

```text
192.168.1.50
```

**An IPv6 address** is 128 bits, written as groups of hexadecimal digits separated by colons. One run of consecutive all-zero groups can be collapsed to `::`, which may appear **at most once** in an address:

```text
2001:db8:0:1:0:0:0:abcd   →   2001:db8:0:1::abcd
```

An interface can hold IPv4 and IPv6 addresses at the same time; the two protocols operate independently.

**The prefix length** is the `/24` or `/64` after an address. It says how many leading bits are fixed as the *network* part; the remaining bits identify a host on that network. It works identically for IPv4 and IPv6 — only the totals differ, because IPv4 has 32 bits and IPv6 has 128.

```text
127.0.0.1/8            first 8 bits are the network part   (loopback)
192.168.50.10/24       first 24 bits are the network part
2001:db8:50::10/64     first 64 bits are the network part
```

Two addresses whose network bits match **at the same prefix length** are on the same local network and can normally communicate directly. Anything else goes through a router — the default gateway, below.

Worked example: take `10.4.1.9/24` and `10.4.2.9/24`. At `/24` the first 24 bits are the network part, so `10.4.1` and `10.4.2` have to match — they do not, so these are different networks and traffic between them is routed. Change both to `/16` and only the first 16 bits count: `10.4` matches for both, so now they are on the same network and talk directly. The digits never changed; the prefix length decided the answer.

### Link-local IPv6 addresses

Any IPv6-capable interface that is `UP` also gives itself a **link-local** address in the `fe80::/64` range automatically — no DHCP server, no manual step. You will often see it as an extra `inet6 fe80::…` line alongside any regular address. A link-local address is valid only on the one segment the interface is attached to and is never routed to other networks, so on its own it does not make the interface reachable from elsewhere. Seeing one on an interface that has no other address is normal.

## Enabled, connected, reachable

Three separate things, and it is common to conflate them.

- **Enabled (UP)** is the administrative state. You, or a boot-time service, asked the kernel to switch the interface on. `ip link show` prints `UP` in the flag list and `state UP` at the end of the line.
- **Connected (LOWER_UP)** means the kernel detects a carrier — a live partner on the other end, such as a switch port or a virtual segment that is wired up. An interface can be `UP` without `LOWER_UP` when nothing is attached.
- **Reachable** means a packet can actually travel from this machine to some other host and back. That needs an address, a route, a working path, and a host at the far end that answers. None of the flags on an interface can promise it.

The playground's two spare segments are isolated: each has one host (this VM) and no router. You can watch link state change, but a `ping` to any address beyond the VM's own will not get a reply — the link-state half is visible here, the end-to-end half is not.

You can change the administrative state yourself with `ip link set`. The command below is safe **only** on one of the two spare NICs. Never run it on the interface carrying your SSH session — bringing that down cuts you off from the machine.

> [!TIP]
> **Try it — turn a spare interface off, then back on**
>
> ```sh
> sudo ip link set enp0s3 down
> ip -brief link show dev enp0s3
> sudo ip link set enp0s3 up
> ip -brief link show dev enp0s3
> ```
>
> Expect `DOWN` after the first change and `UP` again after the last:
>
> ```text
> enp0s3           DOWN           52:54:00:dd:ee:ff <BROADCAST,MULTICAST>
> enp0s3           UP             52:54:00:dd:ee:ff <BROADCAST,MULTICAST,UP,LOWER_UP>
> ```
>
> The MAC address never changes; only the state and the flags do. `UP` is something a command sets and clears — an administrative switch, not a property of the hardware. This change is runtime-only and resets on reboot.

Seeing `<BROADCAST,MULTICAST,UP,LOWER_UP>` and `state UP` on `enp0s3` is tempting to read as "another machine can ping `enp0s3` now." It cannot. Those flags report administrative and link state only. Reachability also needs an address on the interface, a route to the other machine, a working path, and a host at the far end that answers — check the first two with `ip addr show dev enp0s3` and `ip route show`. In this playground `enp0s3` has no address, so nothing beyond the VM answers whatever the flags say.

## Reaching other networks: the default gateway

An address and its prefix length tell the machine which other addresses sit on its own local network — the ones it reaches directly. For anything outside that range, the machine consults its **routing table**: a list of destination networks and how to reach each one. The catch-all entry is the **default route**, and the router it points to is the **default gateway** — where traffic goes when no more specific route matches.

`ip route show` prints the table. It reads state only and changes nothing.

> [!TIP]
> **Try it — show the routing table**
>
> ```sh
> ip route show
> ```
>
> Expect something like:
>
> ```text
> default via 10.0.0.1 dev enp0s1 proto dhcp src 10.0.0.20 metric 100
> 10.0.0.0/24 dev enp0s1 proto kernel scope link src 10.0.0.20
> 192.168.50.0/24 dev enp0s2 proto kernel scope link src 192.168.50.10
> ```
>
> The `default via 10.0.0.1` line is the default gateway, reached through the management interface. Each `scope link` line is a directly connected network — one per interface that has an address, so `enp0s3` (no address) contributes none. The `192.168.50.0/24` and `192.168.51.0/24` segments have no gateway, which is why traffic from them toward the wider world has nowhere to go. Addresses and gateway vary.

## The loopback interface

Every Linux machine has a loopback interface, named `lo`. It is virtual — there is no hardware behind it — and it exists so the machine can send network traffic to itself. Local services that listen on `127.0.0.1` or `::1` are reached through it. Its standard addresses are `127.0.0.1/8` for IPv4 and `::1/128` for IPv6, and traffic on `lo` never leaves the machine.

Loopback is the one interface that is reachable by definition — a useful contrast with the spare NIC that is `UP` but answers nothing.

> [!TIP]
> **Try it — send traffic to the machine itself**
>
> ```sh
> ping -c 2 127.0.0.1
> ping -c 2 ::1
> ```
>
> Expect replies with a near-zero round-trip time:
>
> ```text
> 64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.041 ms
> 64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.052 ms
> ```
>
> Both the IPv4 and IPv6 loopback addresses answer immediately, over `lo`, with no physical network involved. Pinging an address on one of the isolated spare segments would simply time out — same machine, different interface, no host to answer.

## Runtime changes versus persistent configuration

Everything the `ip` command changes — an address added with `ip addr add`, a state set with `ip link set` — takes effect immediately and is held only in the running kernel. A reboot clears all of it. That is fine for exploring and for a temporary fix, but it is not how an address is meant to stay in place.

Persistent addressing is configured through the distribution's network-management system — NetworkManager, Netplan, or `systemd-networkd` on common Linux distributions. That system writes the configuration to disk and reapplies it on every boot. A single interface should be managed by only one such system at a time; two of them configuring the same interface will conflict.

Keep the two kinds of command apart. `ip ... show` and `ip route show` **verify** — they report current state and change nothing. `ip addr add`, `ip addr del`, and `ip link set` **configure** — they change kernel state and need `sudo`.

> [!TIP]
> **Try it — add an address at runtime, then remove it**
>
> `sudo` is required because changing an address alters kernel network state. Only ever do this to one of the two spare NICs, never the interface carrying your SSH session.
>
> ```sh
> sudo ip addr add 192.168.51.20/24 dev enp0s3
> ip -brief addr show dev enp0s3
> sudo ip addr del 192.168.51.20/24 dev enp0s3
> ```
>
> Expect the middle command to show:
>
> ```text
> enp0s3           UP             192.168.51.20/24
> ```
>
> The address appears immediately and is gone again after the `del`. Nothing about this survives a reboot — to make an address stick, configure it through NetworkManager, Netplan, or `systemd-networkd` instead.

> [!WARNING]
> **Common pitfalls**
>
> - **Reading `UP` as "reachable".** An interface can be `UP`, even `LOWER_UP`, with no address and no route. Confirm with `ip addr show` and `ip route show`, not `ip link show` alone.
> - **`::` more than once in an IPv6 address.** `2001:db8::1::2` is invalid — neither a reader nor the parser can tell how many zero groups each `::` stands for. It may appear at most once.
> - **Comparing digits instead of prefixes.** `192.168.1.10/24` and `192.168.2.10/24` look similar but are different networks; the `/24` fixes `192.168.1` versus `192.168.2` as the network part. "Same network" needs matching network bits *at the same prefix length*.
> - **Confusing the MAC address with the IP address.** They belong to different layers. An interface with no IP still has a MAC; adding or removing an IP never changes the MAC.
> - **Expecting `ip` changes to persist.** Anything set with `ip addr add`, `ip addr del`, or `ip link set` lives only in the running kernel and is gone after reboot. Persistent addressing goes through NetworkManager, Netplan, or `systemd-networkd`.
