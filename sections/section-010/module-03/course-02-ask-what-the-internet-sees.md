# Ask The Galaxy What It Sees

Astronaut, your ship cannot read its public call sign from its own antennas, because the relay station applies it further down the lane. The only way to learn it is to send a signal out and ask someone on the far side what call sign they saw.

This part shows you two ways to ask, how to stop a blocked question from hanging, and what the answer does not prove.

## Words you will meet

| Term | Meaning |
|---|---|
| **Egress address** | The public source address that one particular outside service sees for your outgoing connection. |
| **CGNAT** | Carrier-grade NAT: a second layer of address translation run by an internet provider, so even the "public" address you see may be shared with other customers. |

## Discovering the internet-facing address

The public address may exist only on a router. So the machine has to ask an outside service which source address it sees. There are two common ways to ask: over HTTP and over DNS.

### Over HTTP

Request a page from a service that sends your source address back to you. `curl` is the usual client, and `-s` hides its progress meter:

<!-- astrona:playground:renew -->

```bash
curl -s https://ifconfig.me
curl -s https://icanhazip.com
```

### Over DNS

Some DNS servers (offices of the galaxy-wide directory of call signs) return the source address of a question in a TXT record. `dig` is the DNS lookup tool. In the command below, `TXT` asks for a text record, `o-o.myaddr.l.google.com` is a special query name, `@ns1.google.com` sends the question straight to that server, and `+short` cuts the output down to the answer:

```bash
dig +short TXT o-o.myaddr.l.google.com @ns1.google.com
```

### What the answer really is

Both methods return the **observed public egress address**: the address that one service sees for your connection. It might belong to your router, a company firewall, a cloud NAT gateway, an internet provider, a VPN (virtual private network) gateway, an HTTP proxy or a carrier-grade NAT platform. Calling it the machine's "own" public address is not quite right. It is whatever address sits at the network's exit, as seen from that service.

The HTTP and DNS answers can differ, because HTTP traffic and DNS traffic may leave the network by different paths, proxies or forwarders. The DNS question is another way to discover the address, not a way around a firewall policy. Controlled networks often block direct outside DNS on purpose.

### Ask from your training ship

Add a short timeout, so a blocked request fails fast instead of hanging:

```sh
curl --max-time 5 -s https://ifconfig.me; echo
dig +short TXT o-o.myaddr.l.google.com @ns1.google.com
```

There are two possible results:

- **The environment has outgoing internet access.** Each command prints an address: the public egress address that the HTTP service, and the DNS server, see for your connection. It is *not* one of the private addresses on your interfaces; it belongs to a NAT device outside this machine. The two answers can differ if HTTP and DNS leave by different paths.
- **The environment is isolated.** `curl` gives up after five seconds with no output, and `dig` returns nothing. That failure is itself the lesson: the public address is not on this machine, so with no path off it, there is nothing local to read.

> [!TIP]
> Whenever you are not sure a machine can reach the internet, add `--max-time` to `curl`. A short timeout turns a hang into a clear answer.

## IPv4 and IPv6 can differ

A machine can use different public addresses for IPv4 and IPv6 traffic. Force the protocol with `curl -4` or `curl -6`:

```bash
curl -4 -s https://ifconfig.me
curl -6 -s https://ifconfig.me
```

The `-6` form only works where IPv6 connectivity exists. Unlike private IPv4 traffic, globally routable IPv6 traffic often does *not* use NAT. So an interface may carry a globally routable IPv6 address that you can see directly in `ip -6 addr show`. A firewall can still control whether incoming or outgoing IPv6 connections are allowed.

## What a discovered public address does not tell you

A discovered public address does not prove that the internet can reach the machine. Incoming connections can still be blocked by a firewall, by NAT rules with no port forward, by a VPN, a proxy, carrier-grade NAT, cloud security controls or an internet provider.

Public address discovery only tells you which address an outside service sees for an *outgoing* connection. It does not test whether *incoming* connections can arrive.

## Common pitfalls

> [!WARNING]
> - **Treating the egress address as "my server's public IP".** It is the address seen at the network exit, usually on a NAT device you do not control. With shared or carrier-grade NAT it is not even yours alone.
> - **Assuming a discovered address means the machine is reachable from outside.** Egress discovery tests only outgoing connections. Incoming traffic also needs a firewall rule or a port forward, and none of these commands check for one.
> - **Running `curl` with no timeout on an isolated host.** Without `--max-time`, a blocked request can hang for a long time.
> - **Expecting the HTTP and DNS answers to match.** They can differ when the two protocols leave by different paths, proxies or DNS forwarders. A mismatch is information, not an error.

## Your mission: Public IP Discovery Behind NAT Lab

You can now tell a private address from a public one and ask an outside service for your egress address. The mission asks you to find both addresses of a machine and write each one, in an exact format, to the file an audit script reads.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop public-ip-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-03/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-013
astrona start public-ip-playground
```
