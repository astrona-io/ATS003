# Packet Filtering with nftables

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-030/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-030/module-01/playground
> astrona destroy nftables-filtering-playground
> ```

**Packet filtering** is deciding, for every network packet, whether to let it through, discard it, or send back an error. On Linux that decision happens in the kernel's **netfilter** framework, and **nftables** is the current tool for writing the rules that drive it — the successor to `iptables`, `ip6tables`, `arptables`, and `ebtables`, all of which are now thin compatibility shims over the same nftables machinery.

A finished rule looks like this:

```text
tcp dport 22 accept
```

"For a TCP packet whose destination port is 22, accept it." But that rule cannot exist on its own. nftables needs a place to put it, and — unlike `iptables`, which ships with built-in tables and chains — **nftables starts completely empty**. Nothing is filtered until you build the structure, which has four nested layers:

```text
ruleset  ->  tables  ->  chains  ->  rules
```

- A **ruleset** is everything nftables currently holds — every table, chain, and rule together.
- A **table** groups related chains and belongs to one **address family** (`ip`, `ip6`, `inet`, …) that fixes which kinds of packet its chains can see.
- A **chain** holds an ordered list of rules. A **base chain** attaches to a netfilter **hook** — a fixed point on a packet's path through the kernel — so packets actually flow through it. A chain with no hook is just a container other chains can jump into.
- A **rule** is one line: zero or more **matches** (conditions the packet must meet) then one or more **statements** (what to do), such as a **verdict** of `accept` or `drop`.

This module builds that structure from the bottom up, one concept per part, on a live machine.

## How this module is organised

Work through the parts in order. Each is a single sitting, front-loads *why* the concept matters, and ends with the one line worth memorising for the exam. Every part has hands-on **Try it** checkpoints you run on the playground VM.

1. **[Netfilter and the packet path](./course-01-netfilter-and-packet-flow.md)** — the kernel hook framework nftables plugs into: the five hooks, the routing decision, hook priorities, and where a base chain sits in the flow.
2. **[Tables and address families](./course-02-tables-and-families.md)** — what a table really is, all six families (`ip`, `ip6`, `inet`, `arp`, `bridge`, `netdev`), and why `inet` is the right default for a host firewall.
3. **[Chains, hooks, priority, and policy](./course-03-chains-hooks-priority.md)** — base vs regular chains, the four things a base chain declares, `jump`/`goto`, chain policy, and the lock-out trap.
4. **[Rules: matches and verdicts](./course-04-rules-matches-verdicts.md)** — match expressions, verdict and non-verdict statements, rule order, editing by handle, and counters.
5. **[Connection tracking, sets, and maps](./course-05-conntrack-sets-maps.md)** — stateful filtering with `ct state`, and collapsing many rules into one with named sets, maps, and verdict maps.
6. **[Persistence and operating a ruleset](./course-06-persistence-and-operations.md)** — why a ruleset dies on reboot, `/etc/nftables.conf` and `nftables.service`, atomic loads, tracing, and the full pitfalls list.

## Learning objectives

After this module you can:

- Name the five netfilter hooks in the order a packet meets them, and explain which category of traffic (`input`, `forward`, `output`) each base chain sees.
- Explain what a hook **priority** is, why it is a signed integer, and which keyword bands (`raw`, `mangle`, `dstnat`, `filter`, `srcnat`, `security`) map to which numbers.
- Describe the nftables object model — ruleset, table, chain, rule — and explain why nftables starts with an empty ruleset.
- Choose an address family for a table and explain why `inet` covers both IPv4 and IPv6 while `ip`, `ip6`, `bridge`, and `netdev` do not.
- Create a base chain, and name the hook, type, priority, and policy it needs to filter traffic; jump to a regular chain and explain how the verdict returns.
- Write rules that match on `tcp dport`, `ip saddr`, `iif`, and `ct state`, apply `accept` / `drop` / `reject` verdicts, and explain why rule order decides the outcome.
- Read `nft list ruleset` and `nft -a list ruleset`, delete a rule by its handle, `insert` a rule at the top, and add a `counter` to see how often a rule matches.
- Use a named set and a verdict map to replace a block of repetitive rules.
- Explain why an nftables ruleset is lost on reboot, how `/etc/nftables.conf` and `nftables.service` make it persistent, and why `nft -f` applies a whole file atomically.

## Before you start

This module assumes you can open a shell, run commands with `sudo`, and know what a TCP port and an IPv4 address are. Netfilter, hook, address family, verdict, handle, and connection tracking are all defined as they come up. Having seen the interfaces and addressing module helps but is not required.

Open a shell on the playground VM with `astrona ssh astro-nftables-filtering-playground`; every state-changing command uses `sudo`. The playground gives you:

- An **empty nftables ruleset**. `sudo nft list ruleset` prints nothing until you add a table — no stock firewall in the way.
- `nft`, plus `conntrack`, `curl`, `ncat`, and `python3` for generating and observing traffic.
- Two local IPv4 addresses: the **management interface** that carries your SSH session, and **`192.168.80.10/24`** on a local dummy interface, used later for source-address rules. Find their kernel names with `ip -brief -4 addr show`.
- Password-less `sudo`.

Several checkpoints need a listener to filter; you start one yourself with `python3 -m http.server 5000` and restart it as needed. Run it in one SSH session and the `nft` / `curl` commands in a second, or append `&` to background it.

## Where this fits

nftables is the rule-writing layer on top of **netfilter**, the set of hooks the kernel already runs every packet through. Filtering does not replace the rest of the stack: a port only answers if a service is listening on it; nftables can block or allow *reaching* a service, not create one. And on many systems a higher-level tool — `firewalld` (the next module), `ufw`, or a cloud provider's security groups — already manages nftables for you, and hand-written rules can conflict with what it expects. Check what is managing the ruleset before adding rules by hand.
