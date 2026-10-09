# Packet Filtering with nftables

Astronaut, every ship needs shields. On a Linux machine, the shields decide what happens to each **packet**, one burst of signal arriving at or leaving the ship. For every packet they choose one of three things: let it through, let it vanish, or bounce it back with a refusal. That choice is called **packet filtering**.

The shield generator sits in the kernel, the ship's core, and is called **netfilter**. You program it from a console called **nftables** (the `nft` command). nftables replaced the older `iptables`, `ip6tables`, `arptables` and `ebtables` tools. Those old names still work, but today they are thin wrappers that write nftables rules underneath.

A finished rule looks like this:

```text
tcp dport 22 accept
```

It says: "for a TCP packet whose destination port is 22, accept it." (TCP, the Transmission Control Protocol, is the way most programs hold a steady conversation; a port is a numbered radio channel on the antenna.) But that rule cannot stand on its own. Unlike `iptables`, which came with ready-made tables and chains, **nftables starts completely empty**. Nothing is filtered until you build the structure, and the structure has four layers:

```text
ruleset  ->  tables  ->  chains  ->  rules
```

This module builds that structure from the bottom up, one idea per part, on a live machine.

## Learning objectives

After this module you can:

- Name the five netfilter hooks in the order a packet meets them, and say which kind of traffic (`input`, `forward`, `output`) each base chain sees.
- Explain what a hook **priority** is, why it is a signed whole number, and which keyword bands (`raw`, `mangle`, `dstnat`, `filter`, `srcnat`, `security`) map to which numbers.
- Describe the nftables object model (ruleset, table, chain, rule) and explain why nftables starts with an empty ruleset.
- Choose an address family for a table, and explain why `inet` covers both IPv4 and IPv6 while `ip`, `ip6`, `bridge` and `netdev` do not.
- Create a base chain with the hook, type, priority and policy it needs; jump to a regular chain and explain how evaluation comes back.
- Write rules that match on `tcp dport`, `ip saddr`, `iif` and `ct state`, use the `accept`, `drop` and `reject` verdicts, and explain why rule order decides the outcome.
- Read `nft list ruleset` and `nft -a list ruleset`, delete a rule by its handle, `insert` a rule at the top, and add a `counter` to see how often a rule matches.
- Redirect one port to another with a `nat` chain on the `prerouting` hook.
- Use a named set and a verdict map to replace a block of repeated rules.
- Explain why an nftables ruleset is lost on reboot, how `/etc/nftables.conf` and `nftables.service` keep it, and why `nft -f` applies a whole file in one step.

## Before you start

Run a short pre-flight check before your first shield program. Make sure you have the knowledge this module expects, and know what is waiting in your playground.

### What you should already know

- **The shell.** You can open a terminal and run commands with `sudo` (borrowing the captain's authority).
- **Ports and addresses.** You know what a TCP port and an IPv4 address are. Every other term (netfilter, hook, address family, verdict, handle, connection tracking) is explained when it first appears.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. Open a shell on it with `astrona ssh nftables-filtering-playground`. Every command that changes the shields uses `sudo`, and `sudo` needs no password.

| What | Details |
| --- | --- |
| The ruleset | **Empty.** `sudo nft list ruleset` prints nothing until you add a table. There is no stock firewall in the way. |
| Tools | `nft`, plus `conntrack`, `curl`, `ncat` and `python3` to make and watch traffic |
| Management interface | The antenna that carries your SSH session. Never add a rule that drops traffic to it, or you lock yourself out. |
| A second address | `192.168.80.10/24` on a local `dummy` interface, a practice antenna used for rules that match on the source address |

Find the names of both interfaces with `ip -brief -4 addr show`.

Several steps need a program listening on a port, so the shields have something to protect. You start one yourself with `python3 -m http.server 5000`. Run it in one SSH (Secure Shell, the sealed communications channel between ships) session and the `nft` and `curl` commands in a second one, or add `&` to run it in the background.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Netfilter And The Packet Path](./course-01-netfilter-and-packet-flow.md): the five hooks, the routing decision and hook priorities.
2. [Tables And Address Families](./course-02-tables-and-families.md): what a table is, the six families, and why `inet` is the right default.
3. [Chains, Hooks, Priority And Policy](./course-03-chains-hooks-priority.md): base and regular chains, `jump` and `goto`, chain policy and the lock-out trap.
4. [Rules: Matches And Verdicts](./course-04-rules-matches-verdicts.md): how a rule is built, the match expressions and every verdict.
5. [Rule Order, Handles And Redirects](./course-05-rule-order-handles-redirects.md): why order decides everything, editing by handle, counters, source rules and a port redirect.
6. [Connection Tracking](./course-06-connection-tracking.md): stateful filtering with `ct state`.
7. [Sets And Maps](./course-07-sets-and-maps.md): one rule for many values, and verdict maps.
8. [Persistence And Operating A Ruleset](./course-08-persistence-and-operations.md): keeping a ruleset after a reboot, loading it in one step, and watching it work.
9. [Wrap-Up: Mission Debrief](./course-09-wrap-up.md): what you learned, your mission, a self-check and clean-up.

## Why this matters

The shields are the last line of defence on every Linux ship. On the exam you write nftables rules by hand on a live machine and must prove they work, so you need to know where a rule runs, in what order, and what happens to packets that no rule matched.

nftables is also what runs underneath the higher-level firewall tools. `firewalld`, `ufw` and many container tools all write nftables rules for you. When one of them behaves strangely, reading the raw ruleset with `nft list ruleset` is how you find out why.
