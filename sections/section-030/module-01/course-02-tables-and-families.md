# Tables And Address Families

Astronaut, a shield program needs a home before it can hold any checkpoints. In nftables that home is the **table**. This part covers what a table is, and the one choice that matters most when you create one: its **address family**.

Get the family wrong and you can block a port for IPv4 while it stays wide open for IPv6, with nothing in the ruleset to warn you.

## The ruleset is the whole picture

Before tables, one word you will see everywhere. The **ruleset** is not an object you create. It is the name for *everything nftables holds right now*: every table, in every family, with all their chains and rules.

`nft list ruleset` prints it, and `nft flush ruleset` erases it in one step. When someone says "load the ruleset from a file", they mean: replace the whole contents in one go.

## A table is a namespace tied to one family

A table is a shield program: a named container that the checkpoints live in. This section shows the two jobs a table does, and the commands to create and remove one.

### The two jobs of a table

A **table** does two things and only two:

1. It is a **namespace**, a container you put chains, sets, maps and other objects into. Two tables can each hold a chain called `input` without a clash.
2. It is **tied to one address family** when you create it, and that family decides **which kinds of packet its chains can see at all**.

A table on its own filters nothing. It has no hook. It does nothing until you add a base chain inside it.

### Create, list and delete a table

```sh
sudo nft add table inet filter     # family = inet, name = filter
sudo nft list tables               # every table, with its family
sudo nft delete table inet filter  # remove it and everything inside
```

Running `add table` for a table that already exists does no harm, so setup scripts are safe to run twice. The name (`filter` above) is your choice: `filter`, `firewall`, `t`, anything. Only the **family** carries meaning.

## The six families

The family decides which signals a table's checkpoints can even see. Here are all six, with the three that need more than a table row explained below.

### The families at a glance

| Family | Chains can filter | Hooks available | Use it for |
|---|---|---|---|
| `ip` | IPv4 packets only | all 5 | IPv4-only rules; old rule sets moved over from `iptables` |
| `ip6` | IPv6 packets only | all 5 | IPv6-only rules; moved over from `ip6tables` |
| `inet` | **IPv4 and IPv6 together** | all 5 | **host firewalls, the normal choice** |
| `arp` | ARP packets | `input`, `output` | ARP filtering; moved over from `arptables` |
| `bridge` | packets crossing a software bridge (layer 2, the local link) | all 5, at bridge level | filtering between bridge ports; replaces `ebtables` |
| `netdev` | packets straight off one interface, **before** any routing | `ingress`, `egress` | early drop on one interface (fake source addresses, floods) |

ARP, the Address Resolution Protocol, is how a ship finds the antenna serial number (MAC address) that belongs to a call sign on its own lane.

### `inet`: the family to use by default

`inet` does not mean "IPv4 or IPv6, pick one per packet". A chain in an `inet` table sees **both** protocols in the same rule list. `tcp dport 22 accept` in an `inet` chain accepts SSH (Secure Shell, the sealed communications channel between ships) over IPv4 *and* IPv6. When you need one protocol only, you add a match, such as `meta nfproto ipv4` or an IPv6-only match like `ip6 saddr`.

The reason to prefer it is a failure you want to avoid. With separate `ip` and `ip6` tables, it is easy to write a careful `ip` ruleset, forget the `ip6` one, and ship a host where every service is open over IPv6. One `inet` table makes that mistake impossible.

### `netdev`: before routing, on one interface

The `ingress` hook (and `egress`, on newer kernels) fires the moment a frame comes off a *named* interface. That is before `prerouting`, before the routing decision and before connection tracking. So a `netdev` base chain names the device it attaches to:

```sh
sudo nft add table netdev raw
sudo nft 'add chain netdev raw ingress_eth0 { type filter hook ingress device "eth0" priority -500 ; }'
```

It is the cheapest place to drop a flood or a fake source address, because the packet has cost the kernel almost nothing yet. It cannot make routing decisions: there is no "is this for me" answer at this point, only the incoming interface (`iif`).

### `bridge`: the local link

If this host bridges interfaces (a host for virtual machines, or a container bridge), traffic that crosses the bridge between two ports is switched, not routed. So it never touches an `ip`, `ip6` or `inet` `forward` chain. A `bridge` family table filters that local-link path: MAC addresses, VLAN (virtual LAN) tags, and the IP headers inside.

## Start from empty and prove it

An `iptables`-based system boots with built-in `INPUT`, `OUTPUT` and `FORWARD` chains and an `ACCEPT` policy already in place. nftables boots with **nothing**: no tables, no chains, no default policy. Every piece of structure is something you added. See that on your playground.

### An empty ruleset

<!-- astrona:playground:renew -->

Ask nftables for everything it holds:

```sh
sudo nft list ruleset
```

The command succeeds and prints **nothing at all**. That blank is the starting point for every shield program in this module.

### A table alone changes nothing

Now add just a table and list the ruleset again:

```sh
sudo nft add table inet filter
sudo nft list ruleset
```

```text
table inet filter {
}
```

You have an empty namespace. No hook, no rules, no effect on any packet: routing and delivery work exactly as before. Leave it in place; a chain goes into it next.

## Scoping deletes

There are three ways to remove things, from small to large. Pick the smallest one that does the job:

- `nft flush table inet filter` empties the table but keeps it (all chains and rules inside are removed).
- `nft delete table inet filter` removes the table itself and everything in it.
- `nft flush ruleset` wipes **every table in every family** at once. It is the fast way back to the boot state, and also the way back in if you lock yourself out.

A table can also be switched off without deleting it: the table flag `dormant` turns off all of its base chains until you remove the flag.

## Common pitfalls

> [!WARNING]
> - **Filtering in the `ip` family and forgetting IPv6.** Rules in an `ip` table never see IPv6 packets. Use `inet` so one rule list covers both.
> - **Expecting a table to filter.** A table has no hook. Nothing happens until a base chain inside it is attached to a hook.
> - **Using `flush ruleset` when you meant one table.** It removes every table in every family, including ones another tool created.

> *The family is the only choice that matters when you create a table. Pick `inet` for a host firewall, so one rule list covers IPv4 and IPv6 and you cannot protect one while leaving the other open.*
