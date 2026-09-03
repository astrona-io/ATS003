# Part 4 — Rules: matches and verdicts

> Prerequisite: [Part 3 — Chains, hooks, priority, and policy](./course-03-chains-hooks-priority.md). Next: [Part 5 — Connection tracking, sets, and maps](./course-05-conntrack-sets-maps.md).

This is where filtering actually happens. A **rule** is one line in a chain: some **matches** that narrow which packets it applies to, then one or more **statements** that act. This part covers the match expressions you will use most, every verdict, the difference between terminal and non-terminal statements, why rule order is the whole game, and how you edit a ruleset that has no line numbers.

## Anatomy of a rule

```text
ip saddr 192.168.80.0/24   tcp dport 22   counter   accept
└─────────── matches ───────────────────┘ └ statements ┘
```

Evaluation of a single rule: test every match, left to right. **All must be true** (logical AND) for the rule to "match". If they all pass, run the statements in order. If any fails, skip straight to the next rule.

There is no OR *within* a rule — you express OR with a set, `{ 22, 80, 443 }` (Part 5), or with multiple rules.

## Match expressions

Matches read fields out of the packet or its metadata. The ones that cover almost all host filtering:

| Match | Reads | Example |
|---|---|---|
| `ip saddr` / `ip daddr` | IPv4 source / dest address | `ip saddr 10.0.0.0/8` |
| `ip6 saddr` / `ip6 daddr` | IPv6 source / dest address | `ip6 daddr ::1` |
| `tcp dport` / `tcp sport` | TCP destination / source port | `tcp dport 443` |
| `udp dport` / `udp sport` | UDP ports | `udp dport 53` |
| `meta l4proto` | transport protocol, family-agnostic | `meta l4proto { tcp, udp }` |
| `meta nfproto` | `ipv4` or `ipv6` (useful in an `inet` chain) | `meta nfproto ipv6` |
| `iif` / `oif` | **incoming / outgoing interface** (by index, fast) | `iif "lo" accept` |
| `iifname` / `oifname` | interface by name (works for interfaces that may not exist yet) | `iifname "eth0"` |
| `ct state` | connection-tracking state (Part 5) | `ct state established,related` |
| `tcp flags` | TCP flag bits | `tcp flags syn` |
| `icmp type` / `icmpv6 type` | ICMP message type | `icmpv6 type { nd-neighbor-solicit, echo-request }` |

`iif "lo" accept` as the first rule of an `input` chain is near-universal: loopback traffic is always trusted and you want it out of the way before any other test.

## Statements: terminal vs non-terminal

A statement either **ends** evaluation of the ruleset for this packet or it **doesn't**.

### Verdict statements

| Verdict | Effect | Terminal? |
|---|---|---|
| `accept` | let the packet past **this hook** (later hooks still apply) | yes |
| `drop` | discard silently — no reply, sender waits for timeout | yes |
| `reject` | discard **and** send an error (ICMP unreachable, or TCP reset for `reject with tcp reset`) — sender fails fast | yes |
| `queue` | hand the packet to a userspace program via NFQUEUE | yes |
| `jump <chain>` | evaluate `<chain>`, then return here | no (returns) |
| `goto <chain>` | evaluate `<chain>`, do not return | no (falls through to base policy) |
| `continue` | do nothing, move to the next rule | no |
| `return` | leave the current chain; in a base chain this means "apply the policy" | no |

`accept` is not "final for the whole firewall" — it means *this chain/hook is done with the packet*. A packet accepted at `prerouting` still faces the `input` chain.

`drop` vs `reject` is a real design choice: `drop` makes your host look dark (a port scanner has to wait for each timeout), `reject` is friendlier to legitimate clients that hit a closed port (they get "connection refused" immediately instead of hanging).

### Non-terminal statements

These act and let evaluation continue to the next rule:

- `counter` — tally packets and bytes that reached this point.
- `log` — write to the kernel log (`log prefix "dropped: " level warn`). Rate-limit it or a flood becomes a log flood.
- `limit rate 10/second` — used as a match-like guard: the rule only "passes" while under the rate.
- `meta mark set 0x1` — stamp a firewall mark for policy routing or later rules.
- `ct mark set` — stamp the connection, so the mark sticks to every later packet of it.

Because `counter` and `log` are non-terminal, a common debugging pattern is a `log` + `counter` rule *just above* a `drop`, so you can see exactly what the `drop` is catching.

## Rule order is the whole game

Rules in a chain run **top to bottom**. The first terminal verdict wins and evaluation stops. Therefore:

- A broad `drop` placed above a specific `accept` for the same packet makes the `accept` **dead code**.
- `accept` the specific, trusted thing first; `drop` the broad remainder after.

Start a listener to have something to filter:

```sh
python3 -m http.server 5000
```

> [!TIP]
> **Try it — drop a port and watch it go dark**
>
> With the listener running and the `inet filter` / `input` skeleton from Part 3 in place:
>
> ```sh
> curl -sS --max-time 3 http://127.0.0.1:5000/ | head -c 40 ; echo
> sudo nft add rule inet filter input tcp dport 5000 drop
> curl -sS --max-time 3 http://127.0.0.1:5000/ ; echo "exit: $?"
> ```
>
> Expect the first `curl` to print the start of a directory listing and the second to stall three seconds then fail:
>
> ```text
> <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN
> curl: (28) Operation timed out after 3001 milliseconds
> exit: 28
> ```
>
> The rule matched every TCP packet for port 5000 and dropped it — no refusal, no answer at all, which is exactly how `drop` differs from `reject`. Leave the rule for the next checkpoint.

## Editing a ruleset with no line numbers

Rules have no position number you can address. To change or delete one you use its **handle** — an integer the kernel assigns when the rule is created, stable for the life of that rule. `nft -a` ("all") prints handles.

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
> Delete it by that handle (use the number you actually see) and confirm the port answers again:
>
> ```sh
> sudo nft delete rule inet filter input handle 4
> curl -sS --max-time 3 http://127.0.0.1:5000/ | head -c 40 ; echo
> ```
>
> Handles are assigned by the kernel and are **not** sequential — yours will differ.

### `add` vs `insert` vs position

- `nft add rule … input tcp dport 5000 drop` — **append** to the end of the chain.
- `nft insert rule … input tcp dport 22 accept` — prepend to the **front** (position 0).
- `nft add rule … input position 4 tcp dport 80 accept` — insert **after** the rule with handle 4.
- `nft insert rule … input position 4 …` — insert **before** the rule with handle 4.
- `nft replace rule … input handle 4 tcp dport 5000 counter drop` — swap the rule at handle 4 for new text, keeping the handle.

## Counting without blocking

`counter` on its own is not a verdict — it records matches and evaluation carries on. It is the simplest way to answer "is this rule matching anything?"

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
> Expect non-zero totals:
>
> ```text
> tcp dport 5000 counter packets 12 bytes 760
> ```
>
> The traffic still went through — `counter` has no `accept` or `drop` — but the rule shows it was matched. Exact counts vary with how much the client and server exchanged.

## Combining matches: allow one source, deny the rest

All matches in a rule must be true, so `ip saddr X tcp dport P accept` fires only for that source on that port. The blanket `drop` must come **after** it:

```sh
sudo nft add rule inet filter input ip saddr 192.168.80.10 tcp dport 6002 accept
sudo nft add rule inet filter input tcp dport 6002 drop
```

Start a listener on 6002 (`python3 -m http.server 6002` binds every interface), then reach it twice — once with source `192.168.80.10`, once from loopback.

> [!TIP]
> **Try it — same port, two source addresses, two outcomes**
>
> ```sh
> curl -sS --max-time 3 --interface 192.168.80.10 http://192.168.80.10:6002/ | head -c 40 ; echo
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
> The first request's source is `192.168.80.10`, so it hit the `accept` and stopped. The second came from `127.0.0.1`, missed the `accept`, fell to the `drop`. Swap the two rules' order and **both** are dropped — the `accept` is never reached.

> *All matches in a rule are ANDed; the first terminal verdict in the chain wins. That is why you accept the specific trusted case before the broad drop, and why you edit by handle, not by position.*

## Reference

- `man 8 nft`, section "Statements" — every verdict and non-verdict statement with syntax.
- `man 8 nft`, sections "Payload expressions" and "Meta expressions" — the full match vocabulary (`ip`, `tcp`, `meta`, `ct`, …).
- **netfilter.org wiki, "Matching packet headers"** and **"Quick reference-nftables in 10 minutes"** — compact, example-first tours of the match and statement syntax.
