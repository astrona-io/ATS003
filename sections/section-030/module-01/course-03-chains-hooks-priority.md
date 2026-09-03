# Part 3 — Chains, hooks, priority, and policy

> Prerequisite: [Part 2 — Tables and address families](./course-02-tables-and-families.md). Next: [Part 4 — Rules: matches and verdicts](./course-04-rules-matches-verdicts.md).

A table is a bag. A **chain** is the thing packets actually walk through. This part covers the two kinds of chain, the four properties a filtering chain must declare, how one chain calls another, and the single most common way people cut off their own SSH session.

## Two kinds of chain

- A **base chain** is registered on a netfilter hook (Part 1). Packets enter it because the kernel puts them there. It must declare `type`, `hook`, `priority`, and `policy`.
- A **regular chain** (also "non-base") has none of those. No hook, so no packet ever enters it on its own. It is a labelled block of rules that a base chain `jump`s or `goto`s into — a subroutine.

```sh
# base chain — has type/hook/priority/policy
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'

# regular chain — just a name
sudo nft add chain inet filter tcp_in
```

If you create a regular chain and put rules in it but never `jump` to it from a base chain, those rules are **dead** — nothing reaches them. This is a frequent "my rule does nothing" cause.

## The four properties of a base chain

```text
{ type filter hook input priority 0 ; policy accept ; }
   │           │           │              │
   │           │           │              └── verdict for packets no rule matched
   │           │           └── position in the priority-ordered callback line
   │           └── which of the 5 hooks (Part 1) this chain sits on
   └── filter | nat | route — what the chain is allowed to do
```

### `type`

| Type | Grants | Notes |
|---|---|---|
| `filter` | accept / drop / reject / counter / log | the everyday type; valid on every hook |
| `nat` | source/dest address & port rewriting (`snat`, `dnat`, `masquerade`) | only on `prerouting`, `input`, `output`, `postrouting`; relies on connection tracking, so only the **first** packet of a connection hits a `nat` chain — the tracker replays the translation for the rest |
| `route` | as `filter`, plus: if the packet's routing-relevant fields change, the kernel **re-routes** it | `output` only; used for policy routing by mark |

For this module every chain is `type filter`.

### `hook` and `priority`

`hook` is one of `prerouting`, `input`, `forward`, `output`, `postrouting` (Part 1). `priority` is the signed integer that orders this chain against every other callback on the same hook — lower runs first. `priority 0` is the keyword `filter`; that is where ordinary accept/drop belongs, after conntrack (-200) and any NAT.

### `policy`

The **policy** is the verdict applied to a packet that reached the end of the chain without any rule giving it a terminal verdict. Two choices:

- `policy accept` — unmatched traffic is **allowed**; rules exist to carve out what to block. Permissive. This is the default if you omit `policy`.
- `policy drop` — unmatched traffic is **denied**; rules exist to allow the few things that should get through. This is how a real host firewall is built ("default deny").

Policy is not a rule and has no counter of its own by default. It is the fall-through.

> [!TIP]
> **Try it — build the skeleton and read it back**
>
> ```sh
> sudo nft add table inet filter
> sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'
> sudo nft list ruleset
> ```
>
> Expect:
>
> ```text
> table inet filter {
> 	chain input {
> 		type filter hook input priority filter; policy accept;
> 	}
> }
> ```
>
> One table, one base chain hooked to `input` — every packet bound for this host now passes through it — but no rules, so nothing is filtered yet. `nft` prints the numeric priority `0` back as its keyword, `filter`.

## Calling one chain from another: `jump` and `goto`

Both send evaluation into a regular chain. The difference is what happens when that chain finishes:

- `jump target` — when `target` ends (or hits a `return`), evaluation **comes back** to the rule after the `jump`, like a function call.
- `goto target` — when `target` ends, evaluation does **not** come back; it falls through to the calling *base* chain's policy, like a tail call.

Splitting a big `input` chain into per-protocol regular chains keeps it readable and lets the common case exit early:

```sh
sudo nft add chain inet filter tcp_in
sudo nft add rule inet filter tcp_in tcp dport 22 accept
sudo nft add rule inet filter tcp_in tcp dport 443 accept
sudo nft add rule inet filter input meta l4proto tcp jump tcp_in
```

> [!TIP]
> **Try it — jump to a regular chain and watch the verdict return**
>
> ```sh
> sudo nft add chain inet filter probe
> sudo nft add rule inet filter probe counter
> sudo nft add rule inet filter input jump probe
> sudo nft add rule inet filter input counter comment '"after jump"'
> ping -c 2 127.0.0.1 >/dev/null
> sudo nft -a list chain inet filter input
> ```
>
> Expect **both** counters — the one inside `probe` and the "after jump" one in `input` — to be non-zero. `jump` ran `probe`, `probe` had no terminal verdict, so evaluation returned to `input` and continued. Swap `jump` for `goto` and re-test: the "after jump" counter stops incrementing, because `goto` never comes back. Clean up with `sudo nft flush ruleset`.

## The lock-out trap

The moment you set `policy drop` on the `input` chain, **every** packet not explicitly accepted by a rule is discarded — including the packets carrying your SSH session. If there is no `accept` rule for SSH (and, on a real host, for `ct state established,related` — Part 5) *before* you flip the policy, the connection freezes and you cannot reconnect.

> [!WARNING]
> Setting `policy drop` on `input` without first accepting your SSH traffic **will** cut off your session. On this throwaway VM the recovery is `sudo nft flush ruleset` from the serial console, or destroying and re-running the playground. On a real remote machine there may be no way back in. Add the SSH `accept` **before** flipping the policy — and, better, stage the whole ruleset in a file and load it atomically (Part 6) so a broken ruleset never goes live half-applied.

> [!TIP]
> **Try it — flip the policy safely, then undo it**
>
> ```sh
> sudo nft add table inet filter
> sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'
> sudo nft add rule inet filter input ct state established,related accept
> sudo nft add rule inet filter input tcp dport 22 accept
> sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy drop ; }'
> sudo nft list chain inet filter input
> ```
>
> Re-declaring the chain with the same name changes only its policy; the rules stay. Expect `policy drop;`, your SSH session still alive (the `established,related` rule keeps its packets flowing), and any un-accepted port now dark. Put the machine back with:
>
> ```sh
> sudo nft flush ruleset
> ```

> *A base chain declares four things — type, hook, priority, policy — and only a base chain receives packets. `policy drop` denies everything you did not explicitly accept, your own SSH included, so the accept rules go in first.*

## Reference

- `man 8 nft`, section "Chains" — full grammar for `type`/`hook`/`priority`/`policy`, plus `jump`, `goto`, and `return`.
- `man 7 nftables`, "Chain types" — the exact capability and hook restrictions for `filter`, `nat`, and `route`.
- **netfilter.org wiki, "Configuring chains"** (`https://wiki.nftables.org/wiki-nftables/index.php/Configuring_chains`) — examples of base-plus-regular-chain layouts for real rulesets.
