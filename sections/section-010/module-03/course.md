# Discovering Your Public IP Address

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-010/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-03/playground
> astrona destroy public-ip-playground
> ```

A Linux machine can have both a local IP address and an Internet-facing public IP address.

The IP address displayed on a local network interface is not always the address that Internet services see. This commonly happens when the machine is located behind a router using Network Address Translation (NAT).

Two questions with two different answers:

- *What address is on my network card?* — answered locally with `ip addr show`. On a home or office network it is often a **private** address.
- *What address does a remote server see when I connect to it?* — cannot be answered locally; the machine has to ask a service on the Internet. This is the **public egress address**, and it usually belongs to a router or gateway sitting between the machine and the Internet.

The gap between those two answers is what NAT creates, and this chapter is about measuring it.

## Key terms

| Term | Meaning in this chapter |
|---|---|
| **Private address** | An address from an RFC 1918 range, usable only inside a private network, not routed on the public Internet. |
| **Public address** | A globally routable address that Internet hosts can send traffic to. |
| **NAT** | Network Address Translation — a router rewriting addresses as packets cross between a private network and the Internet. |
| **SNAT / masquerading / PAT** | Forms of NAT that replace the private *source* address of outbound traffic with a public one. |
| **Default route** | The route Linux uses for any destination it has no more specific route for; it points at the **default gateway**. |
| **Egress address** | The public source address a particular external service observes for your outbound connection. |
| **CGNAT** | Carrier-grade NAT — a second layer of NAT run by an ISP, so even the "public" address seen may be shared. |

## Private IPv4 addresses

RFC 1918 defines three IPv4 address ranges for use on private networks:

```text
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
```

Examples of private IPv4 addresses include:

```text
10.10.0.25
172.16.5.10
192.168.1.50
```

These addresses can be used inside homes, offices, data centres, and other private networks. They are not directly routable across the public Internet.

Different private networks can reuse the same address ranges. For example, many unrelated networks can contain a machine using `192.168.1.50`.

Display the addresses assigned to the local machine:

```bash
ip addr show
```

> [!TIP]
> **Try it — spot the private ranges on this host**
>
> ```sh
> ip -brief addr show
> ```
>
> Expect something like:
>
> ```text
> lo               UNKNOWN        127.0.0.1/8 ::1/128
> enp0s1           UP             10.x.x.x/24
> enp0s2           UP             172.16.20.50/24
> ```
>
> The playground put the host on two private ranges at once: the management interface in `10.0.0.0/8` and the extra NIC in `172.16.0.0/12`. Neither is a public address — match each against the three RFC 1918 blocks above. A machine with only addresses like these has no public address of its own configured anywhere on it.

## How NAT works

When a machine with a private IPv4 address communicates with an Internet service, its traffic normally passes through a router or firewall.

The router replaces the private source address with an Internet-routable public address. This process is called **Source Network Address Translation**, or **SNAT**.

When multiple private machines share one public address, the process is also commonly called **masquerading** or **Port Address Translation (PAT)**.

A simplified connection might look like this:

```text
Linux machine                    Router                         Internet service
192.168.1.50  ──────────────>  203.0.113.20  ──────────────>  External server
 Private address                 Public address
```

The external service sees the address used by the router, not the private address assigned to the Linux machine.

Because the translation happens on the router, the router's public address normally does not appear in the output from:

```bash
ip addr show
```

## Public IP addresses and default routes

The default route identifies where Linux sends traffic for destinations outside its known local networks:

```bash
ip route show
```

Example:

```text
default via 192.168.1.1 dev eth0
```

In this example:

- `192.168.1.1` is the local default gateway.
- `eth0` is the interface used to reach the gateway.
- The gateway may translate the machine's private address into a public address.

The default gateway address is not necessarily the public IP address. It is normally another private address on the local network.

> [!TIP]
> **Try it — the gateway is private, not public**
>
> ```sh
> ip route show
> ip route get 1.1.1.1
> ```
>
> Expect something like:
>
> ```text
> default via 10.x.x.1 dev enp0s1 ...
> 1.1.1.1 via 10.x.x.1 dev enp0s1 src 10.x.x.x ...
> ```
>
> The `default via` address — where every Internet-bound packet is handed off — is itself a private `10.x` address, and the source address Linux would use is private too. Nothing here is a public address. `ip route get` is a lookup only; it sends no packet, so it works even with no connectivity. Whatever public address the outside world eventually sees is applied further along, by a device this command cannot see.

## Discovering the Internet-facing address

Because the public address might only exist on a router, the Linux machine can ask an external service which source address it sees.

For example:

```bash
curl -s https://ifconfig.me
```

Another service can be used for comparison:

```bash
curl -s https://icanhazip.com
```

The response normally contains an address similar to:

```text
203.0.113.20
```

The returned address is the public egress address observed by that particular service.

It might belong to:

- Your local router.
- A company firewall.
- A cloud NAT gateway.
- An Internet service provider.
- A VPN gateway.
- An HTTP proxy.
- A carrier-grade NAT platform.

For this reason, it is more accurate to call it the **observed public egress address** rather than the machine's own public address.

> [!TIP]
> **Try it — ask the Internet, and see whether this environment can**
>
> Add a short timeout so a blocked request fails fast instead of hanging:
>
> ```sh
> curl --max-time 5 -s https://ifconfig.me; echo
> dig +short TXT o-o.myaddr.l.google.com @ns1.google.com
> ```
>
> Two possible outcomes:
>
> - **This environment has outbound Internet.** Each command prints an address — the public egress address that HTTP service, and that DNS server, see for your connection. It is *not* one of the private addresses from the earlier checkpoints; it belongs to a NAT device outside this VM. The two answers can differ if HTTP and DNS leave by different paths.
> - **This environment is isolated.** `curl` gives up after five seconds with no output; `dig` returns nothing. That failure is itself the lesson: the public address is not on this machine, so with no path off it, there is nothing local to read.

## Distinguishing between IPv4 and IPv6

A machine can use different public addresses for IPv4 and IPv6 traffic.

Force `curl` to use IPv4:

```bash
curl -4 -s https://ifconfig.me
```

Force `curl` to use IPv6:

```bash
curl -6 -s https://ifconfig.me
```

The IPv6 command only succeeds when IPv6 connectivity is available.

Unlike private IPv4 traffic, globally routable IPv6 traffic does not always use NAT. A Linux interface may therefore have a globally routable IPv6 address that is also visible in:

```bash
ip -6 addr show
```

However, firewalls can still control whether inbound or outbound IPv6 connections are allowed.

## Discovering an address using DNS

Some DNS services can report the source address from which they receive a DNS query.

For example:

```bash
dig +short TXT o-o.myaddr.l.google.com @ns1.google.com
```

Example response:

```text
"203.0.113.20"
```

In this command:

- `dig` performs the DNS query.
- `TXT` requests a DNS text record.
- `o-o.myaddr.l.google.com` is the special query name.
- `@ns1.google.com` sends the request directly to the specified DNS server.
- `+short` displays only the answer.

The result is the address observed by the DNS server. It can differ from the address observed by an HTTP service if the network uses different egress paths, proxies, VPNs, or DNS forwarding.

This DNS query is an alternative discovery method. It should not be treated as a way to bypass firewall or security policies. Direct external DNS queries may be blocked intentionally in controlled networks.

## Important limitations

A discovered public address does not prove that the Linux machine is directly accessible from the Internet.

Inbound connectivity may still be prevented by:

- A firewall.
- NAT rules.
- Missing port-forwarding rules.
- A VPN.
- A proxy.
- Carrier-grade NAT.
- Cloud security controls.
- An Internet service provider.

Public IP discovery only identifies the address that an external service observes for the outgoing connection. It does not test whether connections from the Internet can reach the machine.
