## Understanding network interfaces and IPv4 & IPv6 Addressing

A Linux machine can have one or more network interfaces. A network interface is a physical or virtual connection that allows the machine to communicate with a network.

An interface can represent:

- A physical network card, such as an Ethernet or Wi-Fi adapter.
- A virtual interface created by a virtual machine, container platform, VPN, or network bridge.
- The loopback interface, which the machine uses to communicate with itself.

Linux often gives interfaces names such as `eth0`, `ens18`, `enp1s0`, or `wlan0`.

### Does every interface need an IP address?

Not every network interface must have an IP address. However, an interface normally needs one before it can communicate directly with other systems using Layer 3 networking.

A single interface can have:

- No IP address.
- One IPv4 or IPv6 address.
- Multiple IPv4 and IPv6 addresses.

An interface can also be enabled without having an IP address. Linux describes an enabled interface as being **UP**. This does not necessarily mean that it has an IP address or can reach another system.

### IPv4 addresses

An IPv4 address contains 32 bits and is normally written as four decimal numbers separated by periods:

```text
192.168.1.50
```

Each number can have a value between `0` and `255`.

An IPv4 address is commonly followed by a prefix length:

```text
192.168.1.50/24
```

The `/24` describes which part of the address identifies the network.

For example, systems with the following addresses normally belong to the same local network:

```text
192.168.1.10/24
192.168.1.50/24
```

Systems on the same local network can normally communicate directly. Traffic intended for a different network is usually sent through a router called the **default gateway**.

### IPv6 addresses

An IPv6 address contains 128 bits and is written using hexadecimal numbers separated by colons:

```text
2001:db8:0:1:0:0:0:abcd
```

Groups containing zeros can be shortened:

```text
2001:db8:0:1::abcd
```

Like IPv4, an IPv6 address normally includes a prefix length:

```text
2001:db8:0:1::abcd/64
```

The `/64` identifies the network portion of the address.

### Viewing network interfaces in Linux

Use the following command to list the network interfaces known to Linux:

```bash
ip link show
```

This displays information such as:

- The interface name.
- Whether the interface is enabled.
- Its physical or virtual link state.
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

These commands only display the current configuration. They do not make changes, so they are safe to use while exploring Linux networking.