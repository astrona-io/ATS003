# Call Signs, Sectors And The Way Out

Astronaut, an IP address is your ship's call sign. But a call sign alone does not tell you which ships you can hail directly and which ones you can only reach through a relay. The prefix length does that.

This part shows you how to read IPv4 and IPv6 addresses and their prefix lengths, the addresses an interface gives itself, the route your signals take to everywhere else, and the one interface that always answers.

## Words you will meet

| Term | Meaning |
| --- | --- |
| **Prefix length** | The `/24` or `/64` after an address: how many leading bits are the network part. How much of the call sign names the sector, and how much names the ship. |
| **Loopback** | The virtual interface `lo` a machine uses to talk to itself. Always present, normally `127.0.0.1/8` and `::1/128`. The ship's internal intercom. |
| **Default gateway** | The router a machine sends traffic to when it has no more specific route for the destination. The relay ship for "everywhere else". |

## Reading an address

IPv4 and IPv6 write addresses in different ways, but they use the prefix length in exactly the same way. Once you can read one address, you can read both.

### IPv4 and IPv6

**An IPv4 address** is 32 bits, written as four decimal numbers from `0` to `255` separated by dots. These are the old, short call signs:

```text
192.168.1.50
```

**An IPv6 address** is 128 bits, written as groups of hexadecimal digits separated by colons. These are the new, long call signs, and there are far more of them. One run of groups that are all zero can be shortened to `::`, and `::` may appear **at most once** in an address:

```text
2001:db8:0:1:0:0:0:abcd   →   2001:db8:0:1::abcd
```

An interface can hold IPv4 and IPv6 addresses at the same time. The two protocols work independently of each other.

### The prefix length

**The prefix length** is the `/24` or `/64` after an address. It says how many leading bits are fixed as the *network* part. The remaining bits name one host on that network. Think of the network part as the sector of space, and the rest as the ship inside that sector.

It works the same way for IPv4 and IPv6. Only the totals differ, because IPv4 has 32 bits and IPv6 has 128:

```text
127.0.0.1/8            first 8 bits are the network part   (loopback)
192.168.50.10/24       first 24 bits are the network part
2001:db8:50::10/64     first 64 bits are the network part
```

Two addresses whose network bits match **at the same prefix length** are on the same local network. They can normally talk directly, like ships in one sector hailing each other. Anything else goes through a router: the default gateway, described below.

### A worked example

Take `10.4.1.9/24` and `10.4.2.9/24`. At `/24` the first 24 bits are the network part, so `10.4.1` and `10.4.2` would have to match. They do not, so these are different networks, and traffic between them is routed.

Now change both to `/16`. Only the first 16 bits count, and `10.4` matches for both. Now they are on the same network and talk directly. The digits never changed; the prefix length decided the answer.

### Link-local IPv6 addresses

Any interface that speaks IPv6 and is `UP` also gives itself a **link-local** address in the `fe80::/64` range. It does this automatically, with no DHCP server and no manual step. You often see it as an extra `inet6 fe80::…` line next to any regular address.

A link-local address is valid only on the one segment the interface is attached to, and it is never routed to other networks. On its own, it does not make the interface reachable from anywhere else. Seeing one on an interface that has no other address is normal.

## Reaching other networks: the default gateway

An address and its prefix length tell the machine which other addresses sit on its own local network: the ones it reaches directly. For anything outside that range, the kernel looks in its **routing table**. That table is the ship's star chart: a list of destination networks and how to reach each one.

### The default route

The catch-all line in the routing table is the **default route**, the lane for "everywhere else". The router it points to is the **default gateway**: the relay ship that passes your signals on when no more specific route matches.

`ip route show` prints the table. It only reads the state and changes nothing.

### See the routing table

<!-- astrona:playground:renew -->

Show the routing table on your training ship:

```sh
ip route show
```

The output recorded when the module was written:

```text
default via 10.0.0.1 dev enp0s1 proto dhcp src 10.0.0.20 metric 100
10.0.0.0/24 dev enp0s1 proto kernel scope link src 10.0.0.20
192.168.50.0/24 dev enp0s2 proto kernel scope link src 192.168.50.10
```

The `default via 10.0.0.1` line is the default gateway, reached through the management interface. Each `scope link` line is a directly connected network: one for each interface that has an address. The interface with no address adds no line. The `192.168.50.0/24` network has no gateway of its own, which is why traffic from it toward the wider world has nowhere to go. In your playground the addresses, the gateway and the interface names (`netlab-a` instead of `enp0s2`) will differ.

## The loopback interface

Every Linux machine has a loopback interface, named `lo`. It is the ship's internal intercom: virtual, with no hardware behind it, and it exists so the machine can send network traffic to itself.

### What it is for

Local services that listen on `127.0.0.1` or `::1` are reached through `lo`. Its standard addresses are `127.0.0.1/8` for IPv4 and `::1/128` for IPv6, and traffic on `lo` never leaves the machine.

Loopback is the one interface that is reachable by definition. That makes it a useful contrast with a spare interface that is `UP` but answers nothing.

### Send a signal to the ship itself

Ping both loopback addresses:

```sh
ping -c 2 127.0.0.1
ping -c 2 ::1
```

You get replies with a round-trip time close to zero. The recorded output for IPv4:

```text
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.041 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.052 ms
```

Both the IPv4 and the IPv6 loopback addresses answer at once, over `lo`, with no physical network involved. Pinging an address on one of the spare interfaces' networks would simply time out: same machine, different interface, and no host to answer.

## Common pitfalls

> [!WARNING]
> - **Using `::` more than once in an IPv6 address.** `2001:db8::1::2` is not valid. Neither a reader nor the parser can tell how many zero groups each `::` stands for. It may appear at most once.
> - **Comparing digits instead of prefixes.** `192.168.1.10/24` and `192.168.2.10/24` look alike but are different networks: the `/24` fixes `192.168.1` and `192.168.2` as the network part. "Same network" needs matching network bits *at the same prefix length*.
> - **Reading a link-local `fe80::` address as "this interface is reachable".** It is valid only on its own segment and is never routed.
