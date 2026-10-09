# Network Interfaces and IPv4 & IPv6 Addressing

Astronaut, every signal your spaceship sends or receives goes through its communications array. On a Linux machine, each antenna on that array is a **network interface**: a connection point between the operating system and a network. Most interfaces also carry one or more **IP addresses**. An IP address is the ship's call sign: the label other machines use to send signals to this one.

An interface can be:

- a physical network card, such as an Ethernet or Wi-Fi adapter;
- a virtual interface from a virtual machine, a container platform, a VPN (virtual private network) or a bridge;
- the **loopback** interface, which the machine uses to talk to itself, like the ship's internal intercom.

Linux names interfaces `eth0`, `ens18`, `enp1s0`, `wlan0` and so on. The kernel picks the name. The name alone does not decide what the interface can do.

This module teaches you to read both on a live machine: which interfaces exist, what state each one is in, which addresses each one holds, and why an address you set by hand is gone after the next reboot.

## Learning objectives

After this module you can:

- List the network interfaces on a Linux machine and read each one's state, MAC address and MTU with `ip link show`.
- Explain what an IPv4 address, an IPv6 address and a prefix length (`/24`, `/64`) each describe, and decide whether two addresses sit on the same local network.
- Show the IPv4 and IPv6 addresses bound to each interface with `ip addr show`, including an interface that has none.
- Tell apart *enabled* (`UP`), *connected* (`LOWER_UP`) and *reachable*, and name which command reports which.
- Read a routing table with `ip route show` and find the default gateway.
- Explain why a change made with `ip addr add` or `ip link set` is gone after a reboot, and name the systems that make addressing persistent.

## Before you start

Every mission starts with a pre-flight check. Make sure you have the knowledge this module expects, and know what is waiting in your playground.

### What you should already know

- **How to use a shell.** You can open a terminal, type a command and run commands with `sudo`.
- **What an IPv4 address looks like.** You have seen a dotted address such as `192.168.1.10`.

No networking theory is needed. Every term (prefix length, gateway, MAC address and so on) is explained when it first comes up.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. Open a terminal on it with `astrona ssh network-interfaces-playground`.

It has these interfaces:

| Interface | What it is |
| --- | --- |
| `lo` | The loopback interface, with `127.0.0.1/8` and `::1/128` |
| The management interface | A real network card with an address from DHCP. It carries your SSH session and the default route. Leave it alone |
| `netlab-a` | A `dummy` interface (a practice antenna wired to nothing), `UP`, with one IPv4 address `192.168.50.10/24` and one IPv6 address `2001:db8:50::10/64` |
| `netlab-b` | A second `dummy` interface, `UP`, on purpose with no address |

The startup script `bootstrap/prepare.sh` creates `netlab-a` and `netlab-b`. Check the names with `ip -brief link show`. The tools `iproute2` (`ip`), `iputils-ping` and `ethtool` are installed.

Every inspection command in this module works as it is. The few commands that change state are safe **only** on `netlab-a` and `netlab-b`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Antennas And Their State](./course-01-antennas-and-their-state.md): the `ip` command, listing interfaces, an interface with no address, and enabled versus connected versus reachable.
2. [Call Signs, Sectors And The Way Out](./course-02-call-signs-sectors-and-the-way-out.md): IPv4 and IPv6 addresses, prefix lengths, link-local addresses, the default gateway and the loopback interface.
3. [Runtime Changes And Persistent Configuration](./course-03-runtime-and-persistent-configuration.md): adding an address with `ip addr add`, why it does not survive a reboot, and what makes it permanent.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md)

## Why this matters

Interfaces and addresses are the base that all other Linux networking stands on. Routing picks which interface a signal leaves by, using the addresses and prefixes set here. Name resolution (DNS) hands back the same kind of address you put on an interface. Every service that listens on a port binds to one of these addresses, or to all of them at once.

So when a problem later shows up as "the service is unreachable", your first questions come from this module. Is the interface up? Does it have an address? Is there a route?
