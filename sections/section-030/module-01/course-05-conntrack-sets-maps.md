# Part 5 — Connection tracking, sets, and maps

> Prerequisite: [Part 4 — Rules: matches and verdicts](./course-04-rules-matches-verdicts.md). Next: [Part 6 — Persistence and operating a ruleset](./course-06-persistence-and-operations.md).

Everything so far treated each packet in isolation. Real firewalls do not. This part adds the two features that turn a pile of rules into a maintainable ruleset: **connection tracking**, which lets one rule cover the reply traffic for every connection, and **sets / maps**, which collapse dozens of near-identical rules into one.

## Connection tracking

The kernel's **conntrack** subsystem watches traffic and builds a table of **connections** — not just TCP; UDP "connections" and ICMP echo pairs are tracked too. It registers on `prerouting` and `output` at priority **-200**, so by the time your `filter` (0) chain runs, every packet is already stamped with the state of the connection it belongs to.

A connection is identified by a **tuple**: source address, destination address, protocol, and (for TCP/UDP) source and destination ports — plus the inverted tuple for the reply direction. When conntrack sees a packet, it looks up the tuple and classifies the packet:

| `ct state` | Meaning |
|---|---|
| `new` | first packet of a connection conntrack has not seen before |
| `established` | a packet belonging to a connection that has seen traffic in **both** directions |
| `related` | a **new** connection that conntrack knows is spawned by an existing one — an FTP data channel, an ICMP error about a tracked flow |
| `invalid` | a packet conntrack cannot associate with any connection (bad TCP state, out-of-window) — almost always safe to `drop` |
| `untracked` | a packet deliberately exempted from tracking with `notrack` in a `raw` (-300) chain |

### The two rules almost every real ruleset starts with

```sh
sudo nft add rule inet filter input ct state established,related accept
sudo nft add rule inet filter input ct state invalid drop
```

The first rule is the reason "default deny" is workable. You accept the *first* packet of each connection you want (SSH, HTTP, …) with specific rules; every subsequent packet of that connection — and every reply your server sends back that comes *in* — matches `established` and is accepted by this one line. Without it, `policy drop` on `input` would also drop the return traffic for connections your own box initiated.

Put both rules **near the top**, right after `iif "lo" accept`: they handle the bulk of packets, so matching them early is also the fast path.

> [!TIP]
> **Try it — see a connection get tracked, and the state rule carry the reply**
>
> Build a default-deny `input` chain that only opens SSH plus established traffic:
>
> ```sh
> sudo nft flush ruleset
> sudo nft add table inet filter
> sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy drop ; }'
> sudo nft add rule inet filter input iif "lo" accept
> sudo nft add rule inet filter input ct state established,related counter accept
> sudo nft add rule inet filter input tcp dport 22 accept
> ```
>
> Your SSH session stays up. Now start an outbound connection and watch conntrack record it:
>
> ```sh
> curl -sS --max-time 5 http://192.168.80.10/ >/dev/null &
> sudo conntrack -L 2>/dev/null | grep -E 'tcp .* (SYN_SENT|ESTABLISHED)' | head
> ```
>
> Expect a line showing the tracked TCP tuple in both directions. The reply packets coming back in are `established`, so the counter on that rule climbs even though there is no rule explicitly naming the source port curl chose. Re-run `sudo nft list chain inet filter input` and check the `established,related` counter moved.

### `notrack` and helpers

- A rule `ct state untracked` only matches packets you sent through `notrack` in a `raw` (priority -300) chain — done on high-rate flows (DNS servers) where the cost of tracking every packet is not worth it. Untracked packets get no `established` shortcut, so you filter them purely statelessly.
- **Conntrack helpers** (`ct helper set "ftp"`) teach the tracker to parse a protocol's control channel and mark the data channel `related`. Helpers inspect payload, so they are security-sensitive — enable only the ones you need, scoped to the relevant port.

## Sets — one rule for many values

A **set** is a named, typed collection you match against with a single rule. Instead of:

```sh
sudo nft add rule inet filter input tcp dport 22 accept
sudo nft add rule inet filter input tcp dport 80 accept
sudo nft add rule inet filter input tcp dport 443 accept
```

you write one:

```sh
sudo nft add set inet filter allowed_tcp '{ type inet_service ; }'
sudo nft add element inet filter allowed_tcp '{ 22, 80, 443 }'
sudo nft add rule inet filter input tcp dport @allowed_tcp accept
```

`@name` in a rule means "look this up in the set." Set element **types** include `ipv4_addr`, `ipv6_addr`, `inet_service` (a port), `ether_addr`, and `mark`.

- **Anonymous set** — `tcp dport { 22, 80, 443 } accept`. Written inline, no name, cannot be changed without editing the rule. Fine for a fixed list.
- **Named set** — created separately, referenced by `@name`, and you can `add element` / `delete element` at runtime **without touching any rule**. This is how you maintain a live allowlist or blocklist.

Useful set flags:

- `flags interval` — elements can be ranges/CIDRs: `{ 192.168.0.0/16, 10.0.0.0/8 }`.
- `flags timeout` with `timeout 1h` — elements expire on their own. Combined with a rule that does `add @blocklist { ip saddr timeout 10m }`, the ruleset can populate its own blocklist dynamically (a poor man's fail2ban).

> [!TIP]
> **Try it — allow a group of ports with one rule, then change the group live**
>
> ```sh
> sudo nft add set inet filter webports '{ type inet_service ; }'
> sudo nft add element inet filter webports '{ 5000 }'
> sudo nft add rule inet filter input tcp dport @webports accept
> python3 -m http.server 5000 &
> curl -sS --max-time 3 http://127.0.0.1:5000/ | head -c 30 ; echo    # works: 5000 is in the set
> curl -sS --max-time 3 http://127.0.0.1:5001/ ; echo "exit: $?"      # fails: 5001 is not
> sudo nft add element inet filter webports '{ 5001 }'
> python3 -m http.server 5001 &
> curl -sS --max-time 3 http://127.0.0.1:5001/ | head -c 30 ; echo    # now works — no rule was edited
> ```
>
> The `accept` rule never changed; adding `5001` to the set opened it.

## Maps — look up a value

A **map** associates a key with a value. A plain map yields data (an address, a mark); a **verdict map** (`vmap`) yields a *verdict*, letting one rule dispatch many cases in a single hash lookup instead of a long `if/elif` ladder of rules:

```sh
sudo nft add rule inet filter input tcp dport vmap { 22 : accept, 80 : accept, 3306 : drop }
```

That one rule accepts 22 and 80 and drops 3306; anything not a key falls through to the next rule. Named verdict maps can be updated at runtime the same way sets can, and can dispatch to chains: `iifname vmap { "eth0" : jump wan_in, "eth1" : jump lan_in }`.

> [!TIP]
> **Try it — dispatch ports to verdicts with one rule**
>
> ```sh
> sudo nft flush ruleset
> sudo nft add table inet filter
> sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'
> sudo nft add rule inet filter input iif "lo" accept
> sudo nft add rule inet filter input tcp dport vmap { 5000 : drop, 5001 : accept }
> python3 -m http.server 5000 & python3 -m http.server 5001 &
> curl -sS --max-time 3 http://127.0.0.1:5000/ ; echo "exit: $?"        # dropped
> curl -sS --max-time 3 http://127.0.0.1:5001/ | head -c 30 ; echo      # accepted
> ```
>
> One rule, two different verdicts, chosen by port. Clean up with `sudo nft flush ruleset`.

> *Conntrack lets a single `ct state established,related accept` cover the reply traffic of every connection, which is what makes default-deny practical. Named sets and verdict maps let you change what is allowed by editing data, not rules.*

## Reference

- `man 8 nft`, sections "Sets", "Maps", and "Stateful objects" — syntax for typed sets, intervals, timeouts, and verdict maps.
- `man 8 nft`, "Conntrack expressions" — every `ct` selector (`ct state`, `ct status`, `ct mark`, `ct helper`, …).
- `man 8 conntrack` — inspect and delete live connections; invaluable when a state rule behaves unexpectedly.
- **netfilter.org wiki, "Connection tracking"** and **"Sets"** — background on how the tracker classifies packets and worked set/map recipes.
