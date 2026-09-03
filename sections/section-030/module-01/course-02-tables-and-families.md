# Part 2 — Tables and address families

> Prerequisite: [Part 1 — Netfilter and the packet path](./course-01-netfilter-and-packet-flow.md). Next: [Part 3 — Chains, hooks, priority, and policy](./course-03-chains-hooks-priority.md).

You now know *where* rules run. This part is about the outermost container they live in — the **table** — and the single most consequential choice you make when you create one: its **address family**. Get the family wrong and you can block a port on IPv4 while it stays wide open on IPv6, with nothing in the ruleset to warn you.

## The ruleset is the whole picture

The **ruleset** is not an object you create. It is the name for *everything nftables currently holds* — every table, in every family, with all their chains and rules. `nft list ruleset` dumps it; `nft flush ruleset` erases it in one atomic step. When someone says "load the ruleset from a file," they mean: replace the entire contents in one transaction.

## A table is a namespace bound to one family

A **table** does two things and only two:

1. It is a **namespace** — a bag you put chains, sets, maps, and other objects into. Two tables can both contain a chain called `input` without collision.
2. It is **pinned to one address family** at creation, and that family decides **what kinds of packet its chains are even capable of seeing**.

A table on its own filters nothing. It has no hook. It is inert until you add a base chain inside it (Part 3).

```sh
sudo nft add table inet filter     # family = inet, name = filter
sudo nft list tables               # every table, with its family
sudo nft delete table inet filter  # remove it and everything inside
```

`add table` for one that already exists is a harmless no-op, so skeleton scripts are safe to re-run. The name (`filter` above) is arbitrary — `filter`, `firewall`, `t`, anything. Only the **family** carries meaning.

## The six families

| Family | Chains can filter | Hooks available | Use it for |
|---|---|---|---|
| `ip` | IPv4 packets only | all 5 | IPv4-only rules; legacy configs ported from `iptables` |
| `ip6` | IPv6 packets only | all 5 | IPv6-only rules; ported from `ip6tables` |
| `inet` | **IPv4 and IPv6 together** | all 5 | **host firewalls — the normal choice** |
| `arp` | ARP packets | `input`, `output` | ARP filtering; ported from `arptables` |
| `bridge` | packets traversing a software bridge (Layer 2) | all 5, at bridge level | filtering between bridge ports; replaces `ebtables` |
| `netdev` | packets straight off one interface, **before** any routing | `ingress`, `egress` | per-interface early drop (anti-spoof, volumetric drop) |

Three of these deserve more than a table row.

### `inet` — the pseudo-family you should default to

`inet` is not "IPv4 or IPv6, pick one per packet." A chain in an `inet` table sees **both** protocols in the same rule list. `tcp dport 22 accept` in an `inet` chain accepts SSH over v4 *and* v6. When you need to be protocol-specific you add a match — `meta nfproto ipv4` or an `ip6`-only header match like `ip6 saddr`.

The reason to prefer it is a failure mode: with separate `ip` and `ip6` tables it is easy to write a careful `ip` ruleset, forget the `ip6` one, and ship a host whose every service is reachable over IPv6 with no filtering at all. One `inet` table makes that mistake structurally impossible.

### `netdev` — before routing, per interface

`ingress` (and `egress`, on newer kernels) fire the instant a frame is pulled off a *named* interface, before `prerouting`, before the routing decision, before conntrack. A `netdev` base chain therefore names the device it attaches to:

```sh
sudo nft add table netdev raw
sudo nft 'add chain netdev raw ingress_eth0 { type filter hook ingress device "eth0" priority -500 ; }'
```

It is the cheapest possible place to drop a flood or spoofed source, because the packet has cost the kernel almost nothing yet. It cannot make routing-aware decisions (`iif` at this point is all you have — there is no "is this for me" answer yet).

### `bridge` — Layer 2

If this host bridges interfaces (a VM host, a container bridge), traffic that crosses the bridge between two ports is switched, not routed, so it never touches an `ip`/`ip6`/`inet` `forward` chain. A `bridge` family table filters that L2 path — MAC addresses, VLAN tags, and the encapsulated IP headers.

## Start from empty and prove it

An `iptables`-based system boots with built-in `INPUT`/`OUTPUT`/`FORWARD` chains and an `ACCEPT` policy already in place. nftables boots with **nothing** — no tables, no chains, no implicit policy. Every byte of structure is something you added.

> [!TIP]
> **Try it — an empty ruleset**
>
> ```sh
> sudo nft list ruleset
> ```
>
> Expect **no output at all** — the command succeeds and prints nothing. That blank is the baseline every config in this module builds on top of.
>
> Now add just a table and confirm a table alone changes nothing:
>
> ```sh
> sudo nft add table inet filter
> sudo nft list ruleset
> ```
>
> Expect:
>
> ```text
> table inet filter {
> }
> ```
>
> An empty namespace. No hook, no rules, no effect on any packet — routing and delivery are exactly as they were before. Leave it; Part 3 adds a chain to it.

## Scoping deletes

- `nft flush table inet filter` — empty the table but keep it (drops all chains/rules inside).
- `nft delete table inet filter` — remove the table itself and everything in it.
- `nft flush ruleset` — wipe **every table in every family** at once. The fast way back to the boot state; also the recovery move if you lock yourself out (Part 3).

> *The family is the only load-bearing decision when you create a table. Pick `inet` for a host firewall so one rule list covers IPv4 and IPv6 and you cannot protect one while leaving the other open.*

## Reference

- `man 8 nft`, section "Address families" — the authoritative list of families and exactly which hooks each one exposes.
- `man 8 nft`, section "Tables" — table flags (e.g. `dormant` to disable a whole table's base chains without deleting them).
- **netfilter.org wiki, "Nftables families"** (`https://wiki.nftables.org/wiki-nftables/index.php/Nftables_families`) — worked examples of when `netdev` and `bridge` earn their place.
