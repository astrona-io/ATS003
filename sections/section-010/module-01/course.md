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
> `enp0s2` carries one IPv4 address and one IPv6 address at once, each with its own prefix length (`/24` and `/64`). `enp0s3` is `UP` but its address column is empty — enabled, no IP, unreachable at Layer 3. `lo` shows the standard loopback pair `127.0.0.1/8` and `::1/128`. Interface names and the management address vary.

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
> `ip link show` reports `state UP` with a MAC address and an MTU — the interface is switched on. `ip addr show` for the same interface prints no `inet` or `inet6` line at all. That gap is the point: UP is an administrative state, not a guarantee of an address or of reachability.

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
> The address appears immediately and is gone again after the `del`. Anything added this way is runtime-only — a reboot clears it. Persistent addressing is configured through the distribution's network-management system (NetworkManager, Netplan, `systemd-networkd`, or similar), and the same interface should not be configured through more than one of them at once.
