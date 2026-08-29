# Packet Filtering with nftables

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-030/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-030/module-01/playground
> astrona destroy nftables-filtering-playground
> ```

**Packet filtering** is deciding, for every network packet, whether to let it
through, discard it, or send back an error. On Linux this decision happens in
the kernel's **netfilter** framework, and **nftables** is the current tool for
writing the rules that drive it. It is the successor to the older `iptables`,
`ip6tables`, and `ebtables` commands.

One thing sets nftables apart from `iptables` right away: `iptables` starts with
built-in tables and chains already in place, but **nftables starts completely
empty**. Nothing is filtered until you build the structure yourself. That
structure has four layers:

```text
ruleset  ->  tables  ->  chains  ->  rules
```

- A **ruleset** is everything nftables currently holds — every table, chain, and
  rule together. `nft list ruleset` prints all of it.
- A **table** groups related chains. Each table belongs to one **address
  family** (`ip`, `ip6`, `inet`, and a few others) that fixes which kinds of
  packet its chains are allowed to see.
- A **chain** holds an ordered list of rules. A **base chain** attaches to a
  netfilter **hook** — a fixed point on a packet's path through the kernel — so
  that packets actually flow through it. A chain with no hook is just a
  container that other chains can jump into.
- A **rule** is one line: zero or more **matches** (conditions the packet must
  meet) followed by one or more **statements** (what to do), such as a
  **verdict** of `accept` or `drop`.

This module builds that structure one layer at a time on a live machine.

## Learning objectives

After this module you can:

- Describe the nftables object model — ruleset, table, chain, rule — and explain
  why nftables starts with an empty ruleset.
- Choose an address family for a table and explain why `inet` covers both IPv4
  and IPv6.
- Create a base chain, and name the hook, type, priority, and policy it needs to
  filter traffic.
- Write rules that match on `tcp dport` and `ip saddr`, apply `accept` / `drop`
  verdicts, and explain why rule order decides the outcome.
- Read `nft list ruleset` and `nft -a list ruleset`, delete a rule by its
  handle, and add a `counter` to see how often a rule matches.
- Explain why an nftables ruleset is lost on reboot and how `/etc/nftables.conf`
  makes it persistent.

## Before you start

This module assumes you can open a shell, run commands with `sudo`, and know
what a TCP port and an IPv4 address are. Netfilter, hook, address family,
verdict, and handle are all defined as they come up. Having seen the interfaces
and addressing module helps but is not required.

Every checkpoint runs in a shell **on the playground VM** — reach it with
`astrona ssh nftables-filtering-playground` — and every state-changing command
uses `sudo`. The playground gives you:

- An **empty nftables ruleset**. `sudo nft list ruleset` prints nothing until
  you add a table. There is no stock firewall in the way.
- `nft` plus `curl`, `ncat`, and `python3` for generating and observing traffic.
- Two local IPv4 addresses: the **management interface** that carries your SSH
  session, and **`192.168.80.10/24`** on an isolated segment, used later for a
  source-address rule. Find their kernel names with `ip -brief -4 addr show`.
- Password-less `sudo`.

You start test listeners yourself, for example `python3 -m http.server 5000`.
Nothing about the ruleset is pre-built — that is the point.

## The object model, starting from nothing

Before adding anything, it is worth seeing the empty state the machine boots
into. An `iptables`-based system would already show built-in chains here;
nftables shows a blank.

> [!TIP]
> **Try it — an empty ruleset**
>
> ```sh
> sudo nft list ruleset
> ```
>
> Expect **no output at all** — the command succeeds and prints nothing.
>
> That blank is the starting point every nftables config builds from. Every
> table, chain, and rule below is something you add on top of nothing.

## Address families

A table is created inside one address family, and that family fixes what its
chains can filter:

| Family | Sees |
|---|---|
| `ip` | IPv4 packets only |
| `ip6` | IPv6 packets only |
| `inet` | IPv4 and IPv6 together |
| `arp` | ARP packets |
| `bridge` | packets crossing a software bridge |
| `netdev` | packets straight off an interface, before routing |

For host firewalling, `inet` is normally the right choice: one set of rules
covers both IP versions, so you cannot accidentally protect IPv4 while leaving
IPv6 wide open. The rest of this module uses `inet`.

## Creating a table and a base chain

A **table** on its own filters nothing — it is just a namespace for chains. A
**base chain** is what does the work: it names a **hook** (where on the packet
path it runs), a **type** (`filter`, `nat`, or `route`), a **priority** (lower
numbers run earlier), and optionally a **policy** (the verdict applied to a
packet that no rule in the chain matches — `accept` if you do not say).

The hooks for `inet`, in the order a packet meets them:

```text
                          +--> input   --> (local process)
prerouting --> [routing] --+
                          +--> forward --> postrouting --> (out)
(local process) --> output --> [routing] --> postrouting --> (out)
```

To filter traffic **addressed to this machine** — the common case for a server —
you attach a base chain to the `input` hook:

```sh
sudo nft add table inet filter
sudo nft add chain inet filter input '{ type filter hook input priority 0 ; policy accept ; }'
```

`nft add table` for a table that already exists is a harmless no-op, so these
two lines are safe to re-run. `policy accept` means the chain changes nothing on
its own yet — packets it does not match are still accepted.

> [!TIP]
> **Try it — build the skeleton and read it back**
>
> ```sh
> sudo nft add table inet filter
> sudo nft add chain inet filter input '{ type filter hook input priority 0 ; policy accept ; }'
> sudo nft list ruleset
> ```
>
> Expect something like:
>
> ```text
> table inet filter {
> 	chain input {
> 		type filter hook input priority filter; policy accept;
> 	}
> }
> ```
>
> The ruleset now has one table and one base chain, hooked to `input` — so every
> packet bound for this host passes through it — but no rules, so nothing is
> filtered yet. `nft` prints the numeric priority `0` back as its keyword name,
> `filter`.

## Rules, matches, and verdicts

A rule is **matches** then **statements**. A match narrows which packets the
rule applies to — `tcp dport 5000` means "TCP segments whose destination port is
5000". A **verdict statement** decides such a packet's fate:

- `accept` — let the packet past this chain.
- `drop` — discard it immediately and silently. The sender gets no reply and
  waits until it times out.
- `reject` — discard it but send back an error (for example "connection
  refused"), so the sender fails fast.

Rules in a chain are evaluated **top to bottom**. `drop` and `accept` are
terminal: once a packet hits one, evaluation of the chain stops. This is why
**order matters** — a `drop` above an `accept` for the same packet wins, and the
`accept` is never reached.

To see a rule take effect you need something for it to block. Start a throwaway
web server on port 5000 in one SSH session (it stays in the foreground; open a
second session for the `nft` and `curl` commands, or append `&` to background
it):

```sh
python3 -m http.server 5000
```

> [!TIP]
> **Try it — drop a port and watch it go dark**
>
> With the listener running:
>
> ```sh
> curl -sS --max-time 3 http://127.0.0.1:5000/ | head -c 40 ; echo
> sudo nft add rule inet filter input tcp dport 5000 drop
> curl -sS --max-time 3 http://127.0.0.1:5000/ ; echo "exit: $?"
> ```
>
> Expect the first `curl` to print the start of a directory listing, and the
> second to stall for three seconds and then fail:
>
> ```text
> <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN
> curl: (28) Operation timed out after 3001 milliseconds
> exit: 28
> ```
>
> The rule matched every TCP packet for port 5000 and dropped it. The connection
> does not get refused — it gets no answer at all, which is exactly how `drop`
> differs from `reject`. Leave the rule in place for the next checkpoint.

## Rule handles

Rules have no line numbers. To change or remove one you need its **handle** — a
number nftables assigns when the rule is created. `nft -a` ("all") prints them.

> [!TIP]
> **Try it — find a rule's handle and delete just that rule**
>
> ```sh
> sudo nft -a list ruleset
> ```
>
> Expect the drop rule to carry a handle:
>
> ```text
> table inet filter {
> 	chain input { # handle 1
> 		type filter hook input priority filter; policy accept;
> 		tcp dport 5000 drop # handle 4
> 	}
> }
> ```
>
> Then remove it by that handle (use the number you actually see) and confirm
> port 5000 answers again:
>
> ```sh
> sudo nft delete rule inet filter input handle 4
> curl -sS --max-time 3 http://127.0.0.1:5000/ | head -c 40 ; echo
> ```
>
> The rule is gone and the `curl` succeeds. The handle numbers are assigned by
> the kernel and are not sequential — yours will differ.

## Counting traffic with a counter

A `counter` statement is not a verdict. It records how many packets and bytes
have matched the rule, and evaluation carries on to the next rule. It is the
simplest way to see whether a rule is matching anything at all.

> [!TIP]
> **Try it — count packets to a port without blocking them**
>
> ```sh
> sudo nft add rule inet filter input tcp dport 5000 counter
> curl -sS --max-time 3 http://127.0.0.1:5000/ >/dev/null
> curl -sS --max-time 3 http://127.0.0.1:5000/ >/dev/null
> sudo nft list ruleset
> ```
>
> Expect the rule to show non-zero totals:
>
> ```text
> tcp dport 5000 counter packets 12 bytes 760
> ```
>
> The traffic still went through — `counter` has no `accept` or `drop` — but the
> rule now shows it was matched. Exact packet and byte counts vary with how much
> the client and server exchanged.

## Matching on source address

Matches can be combined: a rule fires only when **all** of them are true. A
common pattern is to allow a port for one source address and deny it for
everyone else. Because evaluation stops at the first terminal verdict, the
`accept` for the allowed source must come **before** the blanket `drop`:

```sh
sudo nft add rule inet filter input ip saddr 192.168.80.10 tcp dport 6002 accept
sudo nft add rule inet filter input tcp dport 6002 drop
```

Start a listener on 6002 (`python3 -m http.server 6002` binds every interface),
then reach it two ways: once with the packet's source address set to
`192.168.80.10`, once from loopback.

> [!TIP]
> **Try it — same port, two source addresses, two outcomes**
>
> ```sh
> curl -sS --max-time 3 http://192.168.80.10:6002/ | head -c 40 ; echo
> curl -sS --max-time 3 http://127.0.0.1:6002/ ; echo "exit: $?"
> ```
>
> Expect the first to succeed and the second to time out:
>
> ```text
> <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN
> curl: (28) Operation timed out after 3001 milliseconds
> exit: 28
> ```
>
> The first request's source address is `192.168.80.10`, so it matched the
> `accept` rule and stopped there. The second came from `127.0.0.1`, missed the
> `accept`, fell through to the `drop`, and got nothing back. Swap the two rules'
> order and **both** requests are dropped — the `accept` would never be reached.

## Chain policy and the lock-out trap

A base chain's **policy** is the verdict for any packet no rule matched. So far
the `input` chain has used `policy accept`: unmatched traffic is allowed, and
rules carve out exceptions. A real host firewall usually inverts this —
`policy drop`, with rules that `accept` only what should be allowed.

That inversion is where people lock themselves out. The moment the `input`
policy becomes `drop`, **every** packet the rules do not explicitly accept is
discarded — including the packets carrying your SSH session. If there is no
`accept` rule for SSH first, the connection freezes and you cannot get back in.

> [!WARNING]
> Setting `policy drop` on the `input` chain without first accepting your SSH
> traffic will cut off your session. On this throwaway VM the recovery is
> `sudo nft flush ruleset` (from a console, or by destroying and re-running the
> playground) — on a real remote machine there may be no way back in. Always add
> the SSH `accept` rule **before** flipping the policy.

> [!TIP]
> **Try it — flip the policy safely, then undo it**
>
> Accept SSH first (port 22 — adjust if yours differs), then change the policy,
> then confirm SSH still works while an un-accepted port does not:
>
> ```sh
> sudo nft add rule inet filter input tcp dport 22 accept
> sudo nft add chain inet filter input '{ type filter hook input priority 0 ; policy drop ; }'
> sudo nft list chain inet filter input
> curl -sS --max-time 3 http://127.0.0.1:5000/ ; echo "exit: $?"
> ```
>
> Expect the chain to now read `policy drop;`, your SSH session to stay alive,
> and the `curl` to time out — port 5000 has no `accept`, so the policy drops it:
>
> ```text
> 	type filter hook input priority filter; policy drop;
> curl: (28) Operation timed out after 3001 milliseconds
> exit: 28
> ```
>
> Then put the machine back to a fully open state:
>
> ```sh
> sudo nft flush ruleset
> ```
>
> `flush ruleset` deletes every table, chain, and rule at once — the fast way
> back to the empty state the VM booted with.

## Runtime state versus persistent configuration

Everything `nft` changes lives in the running kernel only. A reboot clears the
entire ruleset — tables, chains, rules, counters, and all.

To make a ruleset persistent, write it to a file and have the system load it at
boot. On Debian and Ubuntu that file is `/etc/nftables.conf`, loaded by
`nftables.service`:

```sh
sudo nft list ruleset | sudo tee /etc/nftables.conf
sudo systemctl enable --now nftables.service
```

`nft -f /etc/nftables.conf` loads such a file by hand. The playground leaves
`nftables.service` disabled, so nothing you build survives a restart unless you
set this up.

> [!TIP]
> **Try it — confirm the ruleset does not survive a reboot**
>
> This restarts the VM and drops your SSH session for about a minute; reconnect
> with `astrona ssh nftables-filtering-playground`.
>
> ```sh
> sudo reboot
> ```
>
> After reconnecting:
>
> ```sh
> sudo nft list ruleset
> ```
>
> Expect no output — the table, chain, and rules you built are gone, back to the
> empty ruleset from the start of the module. Anything that must return after a
> reboot has to be in `/etc/nftables.conf` with the service enabled.

## Where this fits

nftables is the rule-writing layer on top of **netfilter**, the set of hooks the
kernel already runs every packet through. Those hooks sit alongside routing: a
packet is classified as `input`, `forward`, or `output` by the routing decision,
and your base chain only sees the category it hooked. A rule that filters
`input` never affects forwarded traffic, and vice versa.

Filtering also does not replace the rest of the stack. A port only answers if a
service is actually listening on it; nftables can block or allow reaching that
service, but it cannot create one. And on many desktop and server systems a
higher-level tool — `firewalld`, `ufw`, or a cloud provider's security groups —
manages nftables rules for you, so hand-written rules can conflict with what
that tool expects. Check what is already managing the ruleset before adding
rules by hand.

> [!WARNING]
> **Common pitfalls**
>
> - **`policy drop` with no accept for SSH or established connections.** The
>   session dies the instant the policy changes. Add the `accept` rules first;
>   on a real host, also `accept` `ct state established,related` so replies to
>   traffic you started keep flowing.
> - **Filtering in the `ip` family and forgetting IPv6.** Rules in an `ip` table
>   never see IPv6 packets. Use `inet` so one ruleset covers both, or you may
>   block a port on IPv4 while it stays open on IPv6.
> - **A chain with no hook filters nothing.** Only a *base* chain — one with
>   `type`, `hook`, and `priority` — receives packets. A plain chain is inert
>   until another chain does `jump` or `goto` to it.
> - **Expecting line numbers.** Rules are edited and deleted by **handle**
>   (`nft -a list ruleset`), not by position or by retyping the rule text.
> - **Rule order.** Evaluation stops at the first `drop` or `accept`. An
>   `accept` placed after a broader `drop` is dead code.
> - **Expecting rules to persist.** `nft` changes are runtime-only. Persistence
>   is `/etc/nftables.conf` plus an enabled `nftables.service`.
