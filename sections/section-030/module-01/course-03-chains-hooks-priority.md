# Chains, Hooks, Priority And Policy

Astronaut, a table is only a container. A **chain** is a checkpoint on the hull: the thing packets actually walk through. This part covers the two kinds of chain, the four settings a filtering chain must declare, how one chain calls another, and the most common way people cut off their own SSH (Secure Shell, the sealed communications channel between ships) session.

## Two kinds of chain

nftables has two kinds of chain, and only one of them ever receives packets by itself. Knowing which is which explains many "my rule does nothing" moments.

### Base chains and regular chains

- A **base chain** is attached to a netfilter hook, one of the five fixed places on the hull where packets pass (`prerouting`, `input`, `forward`, `output`, `postrouting`). Packets enter it because the kernel puts them there. It must declare `type`, `hook`, `priority` and `policy`.
- A **regular chain** has none of those. It has no hook, so no packet ever enters it on its own. It is a labelled block of rules that a base chain sends packets to with `jump` or `goto`, like a short standard procedure.

```sh
# base chain — has type/hook/priority/policy
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'

# regular chain — just a name
sudo nft add chain inet filter tcp_in
```

If you create a regular chain and put rules in it, but never `jump` to it from a base chain, those rules are **dead**: nothing reaches them. This is a frequent cause of "my rule does nothing".

## The four settings of a base chain

Every base chain declares four things inside its braces. This section takes them one at a time.

```text
{ type filter hook input priority 0 ; policy accept ; }
   │           │           │              │
   │           │           │              └── verdict for packets no rule matched
   │           │           └── position in the priority-ordered callback line
   │           └── which of the 5 hooks this chain sits on
   └── filter | nat | route — what the chain is allowed to do
```

### `type`

| Type | Allows | Notes |
|---|---|---|
| `filter` | accept, drop, reject, counter, log | the everyday type; valid on every hook |
| `nat` | rewriting source and destination addresses and ports (`snat`, `dnat`, `masquerade`, `redirect`) | only on `prerouting`, `input`, `output`, `postrouting`; it relies on connection tracking, so only the **first** packet of a connection hits a `nat` chain, and the tracker repeats the rewrite for the rest |
| `route` | like `filter`, plus: if the packet's routing fields change, the kernel **routes it again** | `output` only; used for routing by packet mark |

NAT stands for network address translation: a relay station that swaps the call sign or channel on a signal as it passes.

### `hook` and `priority`

`hook` is one of `prerouting`, `input`, `forward`, `output` or `postrouting`. `priority` is the signed whole number that orders this chain against every other callback on the same hook: lower runs first. `priority 0` is the keyword `filter`. That is where ordinary accept and drop rules belong, after connection tracking (-200) and any address rewriting.

### `policy`

The **policy** is the verdict for a packet that reached the end of the chain without any rule giving it a final verdict. There are two choices:

- `policy accept`: unmatched traffic is **allowed**; your rules pick out what to block. This is the default if you leave `policy` out.
- `policy drop`: unmatched traffic is **denied**; your rules let in the few things that should get through. This is how a real host firewall is built ("default deny").

The policy is not a rule, and by default it has no counter of its own. It is simply what happens at the end of the line.

## Build the skeleton

Time to put a real checkpoint on your ship's hull. You create a table and one base chain on the `input` hook, then read it back.

### Create a table and a base chain

<!-- astrona:playground:renew -->

```sh
sudo nft add table inet filter
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'
sudo nft list ruleset
```

```text
table inet filter {
	chain input {
		type filter hook input priority filter; policy accept;
	}
}
```

You now have one table and one base chain on the `input` hook. Every packet bound for this host passes through it, but there are no rules, so nothing is filtered yet. `nft` prints the number `0` back as its keyword, `filter`.

## Calling one chain from another: `jump` and `goto`

Big rule lists get hard to read. You can split them into regular chains and call those from a base chain. There are two ways to call, and they differ in what happens afterwards.

### The difference between `jump` and `goto`

Both send evaluation into a regular chain. The difference is what happens when that chain ends:

- `jump target`: when `target` ends (or hits a `return`), evaluation **comes back** to the rule after the `jump`, like calling a procedure and returning.
- `goto target`: when `target` ends, evaluation does **not** come back. It falls through to the policy of the calling *base* chain.

Splitting a big `input` chain into one regular chain per protocol keeps it readable and lets the common case leave early:

```sh
sudo nft add chain inet filter tcp_in
sudo nft add rule inet filter tcp_in tcp dport 22 accept
sudo nft add rule inet filter tcp_in tcp dport 443 accept
sudo nft add rule inet filter input meta l4proto tcp jump tcp_in
```

### Watch the verdict come back

Add a regular chain that only counts, jump to it, and put a second counter after the jump:

```sh
sudo nft add chain inet filter probe
sudo nft add rule inet filter probe counter
sudo nft add rule inet filter input jump probe
sudo nft add rule inet filter input counter comment '"after jump"'
ping -c 2 127.0.0.1 >/dev/null
sudo nft -a list chain inet filter input
```

Look at **both** counters: the one inside `probe` and the "after jump" one in `input` should both be above zero. `jump` ran `probe`, `probe` gave no final verdict, so evaluation came back to `input` and carried on.

Swap `jump` for `goto` and test again: the "after jump" counter stops going up, because `goto` never comes back. Clean up with:

```sh
sudo nft flush ruleset
```

## The lock-out trap

`policy drop` is how real firewalls are built, but it is also the fastest way to cut your own link to mission control. This section shows the trap and a safe way to flip the policy.

### Why `policy drop` can cut you off

The moment you set `policy drop` on the `input` chain, **every** packet that no rule accepted is discarded. That includes the packets carrying your SSH session. If there is no `accept` rule for SSH, and on a real host for `ct state established,related` (packets that belong to a conversation already in progress), *before* you flip the policy, the session freezes and you cannot reconnect.

On this throwaway playground the way back is `sudo nft flush ruleset` from the serial console, or destroying and starting the playground again. On a real remote machine there may be no way back in. So add the SSH `accept` **before** you flip the policy. Better still, write the whole ruleset in a file and load it in one step with `nft -f`, so a broken ruleset never goes live half-built.

### Flip the policy safely, then undo it

```sh
sudo nft add table inet filter
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'
sudo nft add rule inet filter input ct state established,related accept
sudo nft add rule inet filter input tcp dport 22 accept
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy drop ; }'
sudo nft list chain inet filter input
```

Declaring the chain again with the same name changes only its policy; the rules stay. You should see `policy drop;` in the listing. Your SSH session stays alive, because the `established,related` rule keeps its packets flowing, and any port you did not accept now goes dark.

Put the machine back:

```sh
sudo nft flush ruleset
```

> [!TIP]
> Before you change a policy to `drop` on a remote machine, read the chain once more and find your SSH `accept` rule with your own eyes. It takes five seconds and saves a lost machine.

## Common pitfalls

> [!WARNING]
> - **`policy drop` with no accept for SSH or established connections.** The session dies the moment the policy changes. Accept `ct state established,related` and your SSH port first.
> - **A chain with no hook filters nothing.** Only a *base* chain, one with `type`, `hook` and `priority`, receives packets. A regular chain does nothing until another chain uses `jump` or `goto` to reach it.
> - **Expecting `goto` to come back.** After a `goto`, evaluation ends at the base chain's policy, not at the next rule.

> *A base chain declares four things (type, hook, priority, policy), and only a base chain receives packets. `policy drop` denies everything you did not accept, your own SSH included, so the accept rules go in first.*
