# Network Interfaces and IPv4 & IPv6 Addressing

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-010/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-01/playground
> astrona destroy network-interfaces-playground
> ```

A Linux machine can have one or more network interfaces. A network interface is a physical or virtual connection that allows the machine to communicate with a network.

An interface can represent:

- A physical network card, such as an Ethernet or Wi-Fi adapter.
- A virtual interface created by a virtual machine, container platform, VPN, or network bridge.
- The loopback interface, which the machine uses to communicate with itself.

Linux often gives interfaces names such as `eth0`, `ens18`, `enp1s0`, or `wlan0`. The name is a label the kernel assigns; it does not by itself change what the interface can do.

A useful mental model: the **interface** is the doorway between the operating system and a network, and an **IP address** is the address written on that doorway so other machines know where to send traffic. One doorway can carry several addresses, or none at all.

## Learning objectives

After this module you can:

- List the network interfaces on a Linux machine and read their state, MAC address, and MTU with `ip link show`.
- Explain what an IPv4 address, an IPv6 address, and a prefix length (`/24`, `/64`) each describe, and decide whether two addresses are on the same local network.
- Show the IPv4 and IPv6 addresses bound to each interface with `ip addr show`, including an interface that has none.
- Distinguish *enabled* (UP), *connected* (LOWER_UP), and *reachable*, and say which command reports which.
- Read a routing table with `ip route show` and identify the default gateway.
- Explain why a change made with `ip addr add` or `ip link set` disappears on reboot, and name the systems that make addressing persistent.

## Before you start

This module assumes you can open a shell on a Linux machine and run commands, and that you have seen a dotted IPv4 address like `192.168.1.10` before. No prior networking theory is needed — Layer 3, prefix length, gateway, and MAC address are all defined as they come up.

The playground gives you a throwaway Linux VM with four interfaces already in place: the loopback `lo`, one management interface that carries your SSH session and has a real address and a default gateway, and two spare NICs on isolated segments — one with an address, one deliberately left with none. Every inspection command below works against that machine as provisioned; the few state-changing commands are called out and are safe only on the spare NICs.

## Where this fits

Interfaces and addressing are the base layer the rest of Linux networking stands on. Routing decides which interface a packet leaves by, and it can only choose among the addresses and prefixes configured here. Name resolution (DNS) hands back the very kind of address you bind to an interface. Every service that listens on a port binds either to one of these addresses or to all of them at once. When a later problem shows up as "the service is unreachable," the first cuts you make are the distinctions in this module: is the interface up, does it have an address, is there a route.

## Key terms

| Term | Meaning in this chapter |
|---|---|
| **Network interface** | A physical or virtual connection point between the OS and a network, such as `eth0` or `lo`. |
| **Loopback** | A virtual interface (`lo`) a machine uses to talk to itself; always present, normally `127.0.0.1/8` and `::1/128`. |
| **IP address** | The address other systems use to send Layer 3 traffic to this machine, in IPv4 or IPv6 form. |
| **Prefix length** | The `/24` or `/64` after an address; how many leading bits identify the network. |
| **UP** | Kernel state meaning an interface is administratively enabled. It does not imply an address or a working link. |
| **MAC address** | The hardware address of an interface, used to deliver frames on the local network segment. |
| **MTU** | Maximum Transmission Unit — the largest packet the interface sends in one piece. |
| **Default gateway** | The router a machine sends traffic to when it has no specific route for the destination network. |

## Does every interface need an IP address?

Not every network interface must have an IP address. However, an interface normally needs one before it can communicate directly with other systems using Layer 3 networking. **Layer 3** is the layer that moves packets between networks using IP addresses.

A single interface can have:

- No IP address.
- One IPv4 or IPv6 address.
- Multiple IPv4 and IPv6 addresses at the same time.

An interface can also be enabled without having an IP address. Linux describes an enabled interface as being **UP**. This does not necessarily mean that it has an IP address, that a cable is plugged in, or that it can reach another system. UP is only the administrative state — the operating system has switched this interface on.

> [!TIP]
> **Try it — list the interfaces this machine has**
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
> Four interfaces: the loopback `lo`, the management interface that carries your SSH session (it holds the machine's real address), and two extra NICs the playground added. Names and MAC addresses vary. All three real interfaces are `UP` — yet, as the next checkpoint shows, one of them has no IP address.

## IPv4 addresses

An IPv4 address contains 32 bits and is normally written as four decimal numbers separated by periods:

```text
192.168.1.50
```

Each number can have a value between `0` and `255`.

An IPv4 address is commonly followed by a prefix length:

```text
192.168.1.50/24
```

The `/24` describes which part of the address identifies the network. A larger number means more leading bits are fixed as the network part, leaving fewer bits for individual hosts.

For example, systems with the following addresses normally belong to the same local network:

```text
192.168.1.10/24
192.168.1.50/24
```

Systems on the same local network can normally communicate directly. Traffic intended for a different network is usually sent through a router called the **default gateway**.

## IPv6 addresses

An IPv6 address contains 128 bits and is written using hexadecimal numbers in groups separated by colons:

```text
2001:db8:0:1:0:0:0:abcd
```

One run of consecutive all-zero groups can be shortened to `::`, which may appear only once in an address:

```text
2001:db8:0:1::abcd
```

Like IPv4, an IPv6 address normally includes a prefix length:

```text
2001:db8:0:1::abcd/64
```

The `/64` identifies the network portion of the address.

An interface can hold IPv4 and IPv6 addresses at the same time; the two protocols operate independently of each other.

### Link-local IPv6 addresses

An IPv6-capable interface that is `UP` also configures itself a **link-local** address in the `fe80::/64` range, with no DHCP server and no manual step. You will often see it as an extra `inet6 fe80::…` line alongside any regular address. A link-local address is only valid on the one network segment the interface is attached to — it is never routed to other networks — so on its own it does not make the interface reachable from elsewhere. It is normal to see a link-local address even on an interface that has no other IP.

## Prefix length: `/8`, `/24`, `/64`

The number after the slash is the **prefix length** — how many leading bits of the address are fixed as the network identifier. The remaining bits identify a host on that network. It works the same way for IPv4 and IPv6; only the totals differ, because IPv4 has 32 bits and IPv6 has 128.

```text
127.0.0.1/8            loopback — first 8 bits are the network part
192.168.50.10/24       IPv4 host — first 24 bits are the network part
2001:db8:50::10/64     IPv6 host — first 64 bits are the network part
```

Two addresses whose network bits match, at the same prefix length, are on the same local network and can normally communicate directly. A different network means the traffic goes through a router.

As a worked case, take `10.4.1.9/24` and `10.4.2.9/24`. At `/24` the first 24 bits are the network part, so `10.4.1` and `10.4.2` have to match — they do not, so these are different networks and traffic between them goes through a router. Change both to `/16` and only the first 16 bits count: `10.4` matches for both, so now they are on the same network and talk directly. The digits never changed; the prefix length decided the answer.

## Viewing network interfaces in Linux

Use the following command to list the network interfaces known to Linux:

```bash
ip link show
```

This displays information such as:

- The interface name.
- Whether the interface is enabled (`UP`) or not (`DOWN`).
- Its physical or virtual link state (`LOWER_UP` when a carrier is detected).
- Its MAC address.
- Its Maximum Transmission Unit (MTU).

The **MAC address** (for example `52:54:00:11:22:33`) is the hardware address of the interface. It is used to deliver frames to the right device on the local network segment, one hop at a time, underneath the IP layer. Every real interface has its own; the loopback's is all zeros because it never puts a frame on a wire.

The **MTU** (for example `1500`) is the largest packet, in bytes, the interface will send in one piece. A packet larger than the MTU is fragmented or rejected, depending on the protocol. `1500` is the common default for Ethernet.

To display the IPv4 and IPv6 addresses assigned to each interface, run:

```bash
ip addr show
```

You can also inspect a specific interface:

```bash
ip addr show dev eth0
```

Replace `eth0` with the interface name used by your machine.

A shorter, one-line-per-interface summary is often easier to scan:

```bash
ip -brief addr show
```

These commands only display the current configuration. They do not make changes, so they are safe to use while exploring Linux networking.

> [!TIP]
> **Try it — see the addresses, including the interface that has none**
>
> ```sh
> ip -brief addr show
> ```
>
> Expect something like:
>
> ```text
> lo               UNKNOWN        127.0.0.1/8 ::1/128
> enp0s1           UP             10.10.0.20/24
> enp0s2           UP             192.168.50.10/24 2001:db8:50::10/64
> enp0s3           UP
> ```
>
> `enp0s2` carries one IPv4 address and one IPv6 address at once, each with its own prefix length (`/24` and `/64`). `enp0s3` is `UP` but its address column is empty — enabled, no routable IP, unreachable at Layer 3. `lo` shows the standard loopback pair `127.0.0.1/8` and `::1/128`. Interface names and the management address vary, and you may also see an `fe80::` link-local address on the IPv6-capable interfaces.

To see why one interface differs from another, inspect them one at a time. `ip link show dev <name>` answers a link-layer question — is it on, does it have a carrier, what are its MAC address and MTU. `ip addr show dev <name>` answers a separate question — which IP addresses are bound to it. An interface can pass the first check and still have nothing to show for the second.

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
> `ip link show` reports `state UP` with a MAC address and an MTU — the interface is switched on. `ip addr show` for the same interface prints no routable `inet` or `inet6` line. (An `inet6 fe80::…` link-local line may still appear; a link-local address is self-assigned and valid only on the directly attached segment, so it is not the address the interface needs to be reachable across networks.) That gap is the point: UP is an administrative state, not a guarantee of a usable address or of reachability.

## Enabled, connected, reachable

These three describe different things, and it is common to confuse them.

- **Enabled (UP)** is the administrative state. You, or a boot-time service, asked the kernel to switch the interface on. `ip link show` prints `UP` in the flag list and `state UP` at the end of the line.
- **Connected (LOWER_UP)** means the kernel detects a carrier — a live link partner on the other end, such as a switch port or a virtual segment that is wired up. An interface can be `UP` without `LOWER_UP` when nothing is plugged in.
- **Reachable** means a packet can actually travel from this machine to some other host and back. That needs an address, a route, a working path, and a host at the far end that answers. None of the flags on an interface can promise it.

The playground's two extra segments are isolated: each has one host (this VM) and no router. You can watch link state change, but a `ping` to any address beyond the VM's own will not get a reply — the link-state half is visible here, the end-to-end half is not.

You can change the administrative state yourself. The command below is safe **only** on one of the two spare NICs. Never run it on the interface carrying your SSH session — bringing that down cuts you off from the machine.

> [!TIP]
> **Try it — turn a spare interface off and back on**
>
> ```sh
> sudo ip link set enp0s3 down
> ip -brief link show dev enp0s3
> sudo ip link set enp0s3 up
> ip -brief link show dev enp0s3
> ```
>
> Expect the state to read `DOWN` after the first change and `UP` again after the last:
>
> ```text
> enp0s3           DOWN           52:54:00:dd:ee:ff <BROADCAST,MULTICAST>
> enp0s3           UP             52:54:00:dd:ee:ff <BROADCAST,MULTICAST,UP,LOWER_UP>
> ```
>
> The MAC address never changes; only the state and the flags do. `UP` is something a command sets and clears — an administrative switch, not a property of the hardware. This change is runtime-only and resets on reboot.

A concrete trap: `ip link show dev enp0s3` prints `<BROADCAST,MULTICAST,UP,LOWER_UP>` and `state UP`, and it is tempting to read that as "another machine can ping `enp0s3` now." It cannot. `UP` and `LOWER_UP` report only administrative and link state. Reachability also needs an address on the interface, a route to the other machine, a working path, and a host at the far end that answers — check the first two with `ip addr show dev enp0s3` and `ip route show`. In this playground `enp0s3` has no address, so nothing beyond the VM answers whatever the flags say.

## Reaching other networks: the default gateway

An address and its prefix length tell the machine which other addresses sit on its own local network — the ones it can reach directly. For anything outside that range, the machine consults its **routing table**: a list of destination networks and how to reach each one. The catch-all entry is the **default route**, and the router it points to is the **default gateway** — where traffic goes when no more specific route matches.

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
> default via 10.10.0.1 dev enp0s1 proto dhcp src 10.10.0.20 metric 100
> 10.10.0.0/24 dev enp0s1 proto kernel scope link src 10.10.0.20
> 192.168.50.0/24 dev enp0s2 proto kernel scope link src 192.168.50.10
> ```
>
> The `default via 10.10.0.1` line is the default gateway, reached through the management interface. The `scope link` lines are directly connected networks — one per interface that has an address, so `enp0s3` (no address) contributes none. There is no gateway on the `192.168.50.0/24` or `192.168.51.0/24` segments, which is why traffic from them toward the wider world has nowhere to go. Addresses and gateway vary.

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
> Both the IPv4 and IPv6 loopback addresses answer immediately, over `lo`, with no physical network involved. Pinging an address on one of the isolated extra segments would simply time out — same machine, different interface, no host to answer.

## Runtime changes versus persistent configuration

Everything the `ip` command changes — an address added with `ip addr add`, a state set with `ip link set` — takes effect immediately and is held only in the running kernel. A reboot clears all of it. That is fine for exploring and for a temporary fix, but it is not how an address is meant to stay in place.

Persistent addressing is configured through the distribution's network-management system — NetworkManager, Netplan, or `systemd-networkd` on common Linux distributions. That system writes the configuration to disk and reapplies it on every boot. A single interface should be managed by only one such system at a time; two of them configuring the same interface will conflict.

It is also worth separating the two kinds of command you have seen. `ip ... show` and `ip route show` **verify** — they report current state and change nothing. `ip addr add`, `ip addr del`, and `ip link set` **configure** — they change kernel state and need `sudo`.

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
> - **`::` more than once in an IPv6 address.** `2001:db8::1::2` is invalid — a reader (and the parser) cannot tell how many zero groups each `::` stands for. It may appear at most once.
> - **Comparing digits instead of prefixes.** `192.168.1.10/24` and `192.168.2.10/24` look similar but are different networks; the `/24` fixes `192.168.1` versus `192.168.2` as the network part. "Same network" needs matching network bits *at the same prefix length*.
> - **Confusing the MAC address with the IP address.** They belong to different layers. An interface with no IP still has a MAC; adding or removing an IP never changes the MAC.
> - **Expecting `ip` changes to persist.** Anything set with `ip addr add`, `ip addr del`, or `ip link set` lives only in the running kernel and is gone after reboot. Persistent addressing goes through NetworkManager, Netplan, or `systemd-networkd`.
