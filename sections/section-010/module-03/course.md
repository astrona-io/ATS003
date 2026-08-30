# Discovering Your Public IP Address

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-010/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-03/playground
> astrona destroy public-ip-playground
> ```

A Linux machine can have both a local IP address and a different Internet-facing one. The address on a network interface is not always the address a remote server sees, and the gap between the two is what **Network Address Translation (NAT)** creates. This module is about measuring that gap.

Two questions with two different answers:

- *What address is on my network card?* — answered locally with `ip addr show`. On a home, office, or cloud network it is usually a **private** address.
- *What address does a remote server see when I connect to it?* — cannot be answered locally; the machine has to ask a service on the Internet. This is the **public egress address**, and it normally belongs to a router or gateway between the machine and the Internet, not to the machine itself.

## Learning objectives

After this module you can:

- Identify whether an address from `ip addr show` is private (an RFC 1918 range) or public, by matching it to the three private blocks.
- Explain why the address on your interface can differ from the address an Internet server sees, in terms of NAT and SNAT.
- Read `ip route show` to find the default gateway, and explain why that gateway address is normally private, not your public address.
- Query an external HTTP or DNS service to discover the observed public egress address, and add a timeout so a blocked request fails fast instead of hanging.
- Explain why HTTP-based and DNS-based discovery can return different addresses.
- State what a discovered public address does *not* tell you about whether the Internet can reach the machine.

## Before you start

This module assumes you can open a shell and run commands, that you have seen a dotted IPv4 address such as `192.168.1.50`, and that an interface has a name such as `enp0s1`. Private-versus-public ranges, NAT, SNAT, default gateway, and egress address are all defined as they come up. Discovery uses `curl` and `dig`; both are already installed in the playground.

Open a shell on the playground VM with `astrona ssh astro-public-ip-playground`. It sits on two private ranges at once — the management interface in `10.0.0.0/8` and an extra NIC in `172.16.0.0/12` — with no public address configured anywhere on it. Whether the VM can reach the Internet to *ask* for its egress address depends on how the environment was provisioned; the discovery checkpoint works either way, and a request that times out is part of the lesson, not a failure to fix.

## Key terms

| Term | Meaning in this module |
|---|---|
| **Private address** | An address from an RFC 1918 range, usable only inside a private network, not routed on the public Internet. |
| **Public address** | A globally routable address that Internet hosts can send traffic to. |
| **NAT** | Network Address Translation — a router rewriting addresses as packets cross between a private network and the Internet. |
| **SNAT / masquerading / PAT** | Forms of NAT that replace the private *source* address of outbound traffic with a public one. |
| **Default route** | The route Linux uses for any destination it has no more specific route for; it points at the **default gateway**. |
| **Egress address** | The public source address a particular external service observes for your outbound connection. |
| **CGNAT** | Carrier-grade NAT — a second layer of NAT run by an ISP, so even the "public" address seen may be shared. |

## Private IPv4 addresses

RFC 1918 sets aside three IPv4 ranges for private networks:

```text
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
```

Addresses in these ranges — `10.10.0.25`, `172.16.5.10`, `192.168.1.50` — are used inside homes, offices, data centres, and cloud VPCs. They are not routed across the public Internet, and different private networks reuse the same ranges freely: countless unrelated networks contain a `192.168.1.50`.

`ip addr show` lists the addresses on the local machine; `ip -brief addr show` is the compact form.

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

When a machine with a private address connects to an Internet service, its traffic passes through a router or firewall. The router replaces the private source address with an Internet-routable public address — **Source Network Address Translation**, or **SNAT**. When many private machines share one public address, the same process is called **masquerading** or **Port Address Translation (PAT)**.

```text
Linux machine                    Router                         Internet service
192.168.1.50  ──────────────>  203.0.113.20  ──────────────>  External server
 Private address                 Public address
```

The external service sees the router's address, not the private one on the Linux machine. Because the translation happens on the router, the router's public address does not appear in `ip addr show` on the machine.

## Public IP addresses and default routes

The **default route** identifies where Linux sends traffic for destinations outside its known local networks. `ip route show` prints it:

```text
default via 192.168.1.1 dev eth0
```

Here `192.168.1.1` is the **default gateway** and `eth0` is the interface used to reach it. That gateway address is not the public IP address — it is normally another private address on the local network. The gateway (or a device beyond it) is where NAT happens.

`ip route get 1.1.1.1` shows which interface and gateway Linux *would* use to reach a given address, as a lookup only — it sends no packet, so it works even with no connectivity.

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
> The `default via` address — where every Internet-bound packet is handed off — is itself a private `10.x` address, and the source address Linux would use is private too. Nothing here is a public address. Whatever public address the outside world eventually sees is applied further along, by a device this command cannot see.

## Discovering the Internet-facing address

Because the public address may exist only on a router, the machine has to ask an external service which source address it sees. There are two common methods:

**Over HTTP** — request a page from a service that echoes your source address back. `curl` is the usual client; `-s` silences its progress meter:

```bash
curl -s https://ifconfig.me
curl -s https://icanhazip.com
```

**Over DNS** — some DNS servers return the source address of the query in a TXT record. `dig` is the DNS lookup tool; here `TXT` asks for a text record, `o-o.myaddr.l.google.com` is a special query name, `@ns1.google.com` sends the query straight to that server, and `+short` trims the output to the answer:

```bash
dig +short TXT o-o.myaddr.l.google.com @ns1.google.com
```

Both return the **observed public egress address** — the address that particular service sees for your connection. It might belong to your router, a company firewall, a cloud NAT gateway, an ISP, a VPN gateway, an HTTP proxy, or a carrier-grade NAT platform. Calling it the machine's "own" public address is imprecise; it is whatever address sits at the network's exit as seen from that vantage point.

The HTTP and DNS answers can differ, because HTTP traffic and DNS traffic may leave the network by different paths, proxies, or forwarders. This DNS query is an alternative discovery method, not a way around firewall policy — controlled networks often block direct external DNS on purpose.

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

## IPv4 and IPv6 can differ

A machine can use different public addresses for IPv4 and IPv6 traffic. Force the protocol with `curl -4` or `curl -6`:

```bash
curl -4 -s https://ifconfig.me
curl -6 -s https://ifconfig.me
```

The `-6` form only succeeds where IPv6 connectivity exists. Unlike private IPv4 traffic, globally routable IPv6 traffic often does *not* use NAT, so an interface may carry a globally routable IPv6 address that is visible directly in `ip -6 addr show`. A firewall can still control whether inbound or outbound IPv6 connections are allowed.

## What a discovered public address does not tell you

A discovered public address does not prove the Internet can reach the machine. Inbound connectivity can still be blocked by a firewall, NAT rules with no port-forward, a VPN, a proxy, carrier-grade NAT, cloud security controls, or an ISP. Public-IP discovery identifies only the address an external service observes for an *outgoing* connection; it does not test whether *incoming* connections can arrive.

> [!WARNING]
> **Common pitfalls**
>
> - **Treating the egress address as "my server's public IP".** It is the address seen at the network exit, usually on a NAT device you do not control. On shared or carrier-grade NAT it is not even yours alone.
> - **Assuming a discovered address means the machine is reachable from outside.** Egress discovery tests only outbound connections. Inbound needs a firewall rule or port-forward as well, and none of these commands check for one.
> - **Running `curl` with no timeout on an isolated host.** Without `--max-time`, a blocked request can hang for a long time. Always set a short timeout when connectivity is uncertain.
> - **Expecting the HTTP and DNS answers to match.** They can legitimately differ when the two protocols leave by different paths, proxies, or DNS forwarders. A mismatch is information, not an error.
> - **Reading the `default via` gateway as the public address.** The default gateway is normally another private address on the local network; the public address is applied further along the path.
