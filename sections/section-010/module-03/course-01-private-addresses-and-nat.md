# Private Call Signs And The Relay Station

Astronaut, most ships never show their own call sign to the wider galaxy. They use a call sign that only works inside the home fleet, and a relay station swaps it for a public one on the way out.

This part shows you how to spot those private call signs on your machine, how the relay station (NAT) does the swap, and why the gateway in your routing table is not your public address either.

## Words you will meet

| Term | Meaning |
|---|---|
| **Private address** | An address from an RFC 1918 range, usable only inside a private network and not routed on the public internet. A call sign used only inside the home fleet. |
| **Public address** | A globally routable address that internet hosts can send traffic to. The call sign the wider galaxy sees. |
| **NAT** | Network address translation: a router rewriting addresses as packets cross between a private network and the internet. The relay station that swaps call signs. |
| **SNAT / masquerading / PAT** | Forms of NAT that replace the private *source* address of outgoing traffic with a public one. |
| **Default route** | The route Linux uses for any destination it has no more specific route for. It points at the **default gateway**. |

## Private IPv4 addresses

A standard called RFC 1918 sets aside three IPv4 ranges for private networks:

```text
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
```

### Who uses them

Addresses in these ranges, such as `10.10.0.25`, `172.16.5.10` and `192.168.1.50`, are used inside homes, offices, data centres and cloud networks. They are not routed across the public internet. Different private networks reuse the same ranges freely: countless unrelated networks contain a `192.168.1.50`.

`ip addr show` lists the addresses on the local machine, and `ip -brief addr show` is the short form.

### Spot the private ranges on your training ship

<!-- astrona:playground:renew -->

List the addresses in the short form:

```sh
ip -brief addr show
```

The output looked like this when the module was written:

```text
lo               UNKNOWN        127.0.0.1/8 ::1/128
enp0s1           UP             10.x.x.x/24
enp0s2           UP             172.16.20.50/24
```

The playground put the machine on two private ranges at once: the management interface in `10.0.0.0/8` and the extra interface in `172.16.0.0/12`. Neither is a public address; match each one against the three RFC 1918 blocks above. A machine with only addresses like these has no public address of its own set anywhere on it. Your interface names may differ.

## How NAT works

When a machine with a private address connects to an internet service, its traffic passes through a router or a firewall. That router does the swap, not the Linux machine.

### Source NAT

The router replaces the private source address with a public address that the internet can route. This is **source network address translation**, or **SNAT**. When many private machines share one public address, the same process is called **masquerading** or **port address translation (PAT)**.

```text
Linux machine                    Router                         Internet service
192.168.1.50  ──────────────>  203.0.113.20  ──────────────>  External server
 Private address                 Public address
```

The same flow as a diagram:

```mermaid
flowchart LR
    M["Linux machine"] -->|"from 192.168.1.50"| R["Router"]
    R -->|"from 203.0.113.20"| S["External server"]
```

The external server sees the router's address, not the private one on the Linux machine.

### Why `ip addr show` cannot show it

The translation happens on the router. So the router's public address does not appear in `ip addr show` on the machine. Nothing you run on the machine itself reads it from an interface.

## The default route is not the public address

The **default route** tells Linux where to send traffic for any destination outside its known local networks: the lane for "everywhere else". It is tempting to read its address as your public address. It is not.

### Read the default route

`ip route show` prints it:

```text
default via 192.168.1.1 dev eth0
```

Here `192.168.1.1` is the **default gateway**, and `eth0` is the interface used to reach it. That gateway address is not the public IP address. It is normally another private address on the local network. The gateway, or a device beyond it, is where NAT happens.

`ip route get 1.1.1.1` shows which interface and gateway Linux *would* use to reach a given address. It only looks this up in the routing table and sends no packet, so it works even with no connectivity.

### The gateway is private too

Show the routing table and look up the way to an internet address:

```sh
ip route show
ip route get 1.1.1.1
```

The recorded output, with the addresses shortened:

```text
default via 10.x.x.1 dev enp0s1 ...
1.1.1.1 via 10.x.x.1 dev enp0s1 src 10.x.x.x ...
```

The `default via` address, where every internet-bound packet is handed off, is itself a private `10.x` address. The source address Linux would use is private too. Nothing here is a public address. Whatever public address the outside world sees is applied further along the way, by a device this command cannot see.

## Common pitfalls

> [!WARNING]
> - **Reading the `default via` gateway as the public address.** The default gateway is normally another private address on the local network. The public address is applied further along the path.
> - **Looking for the public address in `ip addr show`.** When NAT is in use, the public address lives on the router, not on any interface of your machine.
> - **Forgetting the middle range is `/12`.** `172.16.0.0/12` covers `172.16.x.x` to `172.31.x.x`, not only `172.16.x.x`.
