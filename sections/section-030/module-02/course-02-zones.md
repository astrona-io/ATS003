# Part 2 — Zones

> Prerequisite: [Part 1 — Architecture and the nftables backend](./course-01-architecture-and-backends.md). Next: [Part 3 — Services, ports, and rich rules](./course-03-services-ports-richrules.md).

A **zone** is the central object in firewalld. Everything you allow, you allow *in a zone*; every packet is handled *by a zone*. This part is what a zone contains, the built-in zones and how permissive each one is, and — the part people get wrong — the exact precedence that decides which zone a given packet lands in.

## A zone is a named policy

A zone bundles:

- a **target** — what happens to a packet that matches no rule in the zone;
- a list of allowed **services** (Part 3);
- a list of allowed **ports** and **protocols**;
- optional **rich rules**, **port forwards**, **masquerade**, and ICMP filters;
- the **interfaces** and **source addresses** bound to it.

> **Analogy — building entrances.** A zone is a door with its own guard and its own guest list. `public` is the street entrance: a short list, everyone else turned away. `trusted` is the door to your own office: no list, everyone in. Which door a visitor uses is decided by where they came from, not by the visitor.

`firewall-cmd --zone=<name> --list-all` prints one zone's entire policy. With no `--zone` it shows the **default** zone.

> [!TIP]
> **Try it — read the public zone's policy**
>
> ```sh
> sudo firewall-cmd --zone=public --list-all
> ```
>
> Expect something like:
>
> ```text
> public (active)
>   target: default
>   interfaces: enp0s1 enp0s2
>   services: dhcpv6-client ssh
>   ports:
>   ...
> ```
>
> `services: … ssh` is why your SSH session survived firewalld starting — port 22 is allowed in the zone your management interface sits in. The `ports:` line is empty because nothing has opened a raw port yet.

## The target: what "no match" does

| Target | Unmatched packet |
|---|---|
| `default` | rejected with an ICMP error (the usual case; behaves like `%%REJECT%%` for incoming traffic but also allows ICMP and lets you see forwarded/outbound behaviour differ) |
| `%%REJECT%%` | rejected with an ICMP error — sender fails fast |
| `DROP` | dropped silently — sender waits for timeout, host looks dark |
| `ACCEPT` | accepted — the zone is an allowlist of *denies* rather than allows |

`drop` and `block` zones get their behaviour from their target; `trusted` has target `ACCEPT`.

## The built-in zones, least to most permissive

| Zone | Target | Typical use |
|---|---|---|
| `drop` | `DROP` | incoming denied and **silent**; outbound still works. Hostile networks. |
| `block` | `%%REJECT%%` | incoming denied but **with an ICMP reject**; outbound still works. |
| `public` | `default` | **the stock default.** Untrusted network; only explicitly allowed services (SSH, DHCPv6) get in. |
| `external` | `default` | like `public` but with **masquerade on** — for a gateway's outward-facing interface. |
| `dmz` | `default` | for hosts in a DMZ: limited incoming, no masquerade. |
| `work` | `default` | mostly-trusted network; a few more services allowed. |
| `home` | `default` | like `work`, slightly more open (allows `mdns`, `samba-client`, …). |
| `internal` | `default` | trusted internal network; the most open of the "default"-target zones. |
| `trusted` | `ACCEPT` | **everything allowed.** Use only where you fully control the network. |

You can also create your own zone: `firewall-cmd --permanent --new-zone=bastion`, then `--reload`.

## How a packet's zone is chosen — the precedence rule

This is the exam point. For an incoming packet, firewalld picks **exactly one** zone, checking in this order and stopping at the first match:

1. **Source-based binding** — is the packet's source address (or range) bound to a zone (`--add-source=`)? If yes, that zone. Source bindings win over everything.
2. **Interface-based binding** — is the packet's *incoming interface* bound to a zone (`--change-interface=` / `--add-interface=`)? If yes, that zone.
3. **The default zone** — anything not matched above.

So an interface that you never explicitly assigned is handled by the **default zone**, not by whatever zone you happened to be editing. And a source binding overrides the interface: bind `10.0.0.0/8` to `internal` and traffic from that range is `internal` *even if it arrives on an interface bound to `public`*.

Three query commands map to the three levels:

- `firewall-cmd --get-default-zone` — level 3.
- `firewall-cmd --get-zone-of-interface=<dev>` — what level 2 says for one interface.
- `firewall-cmd --get-zone-of-source=<addr>` — what level 1 says for one source.
- `firewall-cmd --get-active-zones` — every zone that currently has an interface **or** a source bound, and what is bound to it.

> [!TIP]
> **Try it — where does firewalld stand right now**
>
> ```sh
> sudo firewall-cmd --state
> sudo firewall-cmd --get-default-zone
> sudo firewall-cmd --get-active-zones
> ```
>
> Expect something like:
>
> ```text
> running
> public
> public
>   interfaces: enp0s1 enp0s2
> ```
>
> The daemon is `running`, the default zone is `public`, and both interfaces are in `public` — neither was assigned elsewhere, so both fall through to the default (level 3). Interface names vary.

## Moving an interface, and binding a source

`firewall-cmd --zone=<name> --change-interface=<dev>` moves an interface into a zone (and out of whatever zone it was in). Different zones allow different things, so the move changes what that interface's traffic can reach.

> [!TIP]
> **Try it — move the spare interface into another zone**
>
> Use the kernel name of the `192.168.90.10` interface (from `ip -brief -4 addr show`; the examples call it `enp0s2`). **Do not** run this against the management interface — moving it to a zone without `ssh` cuts your session.
>
> ```sh
> sudo firewall-cmd --zone=internal --change-interface=enp0s2
> sudo firewall-cmd --get-active-zones
> ```
>
> Expect the interface to have moved:
>
> ```text
> internal
>   interfaces: enp0s2
> public
>   interfaces: enp0s1
> ```
>
> `enp0s2` is now handled by `internal`'s policy; `enp0s1` (your SSH interface) stays in `public`. A packet arriving on `192.168.90.10` is now matched against `internal`.

> [!TIP]
> **Try it — a source binding overrides the interface**
>
> With `enp0s2` still in `internal`, bind its address to `drop` by source and watch source precedence win:
>
> ```sh
> sudo firewall-cmd --zone=drop --add-source=192.168.90.10
> sudo firewall-cmd --get-active-zones
> sudo firewall-cmd --get-zone-of-source=192.168.90.10
> ```
>
> Expect `192.168.90.10` listed under `drop` even though its interface is bound to `internal` — a packet from that address is now handled by `drop` (level 1 beats level 2). Undo with `sudo firewall-cmd --zone=drop --remove-source=192.168.90.10` and `sudo firewall-cmd --zone=public --change-interface=enp0s2`.

> *Every packet is handled by exactly one zone, chosen source-binding first, then interface-binding, then the default zone. An interface you never assigned is in the default zone — not the one you were editing.*

## Reference

- `man 5 firewalld.zone` — the XML schema: `target`, `service`, `port`, `source`, `interface`, `rule`.
- `man 5 firewalld.zones` — prose descriptions of every built-in zone and exactly what each allows out of the box.
- `firewall-cmd --get-zones` / `--info-zone=<name>` — list all zones and dump one zone's definition without `--list-all`'s "active" filtering.
- **firewalld.org, "Zones"** (`https://firewalld.org/documentation/zone/`) — the concept page, including the source-vs-interface precedence.
