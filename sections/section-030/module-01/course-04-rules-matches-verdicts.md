# Rules: Matches And Verdicts

Astronaut, this is where the shields actually act. A **rule** is one line a checkpoint reads: some **matches** that narrow down which packets it applies to, then one or more **statements** that do something.

This part covers how a rule is built, the match expressions you will use most, every verdict, and the difference between statements that end the check and statements that let it carry on.

## How a rule is built

Every rule has the same two halves. Once you can see them, any nftables rule becomes easy to read.

### Matches, then statements

```text
ip saddr 192.168.80.0/24   tcp dport 22   counter   accept
└─────────── matches ───────────────────┘ └ statements ┘
```

The kernel checks a single rule like this: it tests every match, from left to right. **All of them must be true** for the rule to match. If they all pass, it runs the statements in order. If any match fails, it skips straight to the next rule.

There is no "or" *inside* a rule. You write "or" with a set of values, such as `{ 22, 80, 443 }`, or with several rules.

## Match expressions

Matches read fields from the packet or from facts about it, such as which antenna it arrived on. The ones below cover almost all host filtering.

### The matches you will use most

| Match | Reads | Example |
|---|---|---|
| `ip saddr` / `ip daddr` | IPv4 source / destination address | `ip saddr 10.0.0.0/8` |
| `ip6 saddr` / `ip6 daddr` | IPv6 source / destination address | `ip6 daddr ::1` |
| `tcp dport` / `tcp sport` | TCP destination / source port | `tcp dport 443` |
| `udp dport` / `udp sport` | UDP ports | `udp dport 53` |
| `meta l4proto` | the transport protocol, for any family | `meta l4proto { tcp, udp }` |
| `meta nfproto` | `ipv4` or `ipv6` (useful in an `inet` chain) | `meta nfproto ipv6` |
| `iif` / `oif` | **incoming / outgoing interface** (by number, fast) | `iif "lo" accept` |
| `iifname` / `oifname` | interface by name (works for interfaces that may not exist yet) | `iifname "eth0"` |
| `ct state` | the connection tracking state | `ct state established,related` |
| `tcp flags` | TCP flag bits | `tcp flags syn` |
| `icmp type` / `icmpv6 type` | ICMP message type | `icmpv6 type { nd-neighbor-solicit, echo-request }` |

UDP, the User Datagram Protocol, sends single signal bursts with no conversation around them. ICMP, the Internet Control Message Protocol, carries short status messages such as ping and "cannot reach".

### Trust the intercom first

`iif "lo" accept` as the first rule of an `input` chain is almost universal. Loopback traffic (the ship's internal intercom) is always trusted, and you want it out of the way before any other test runs.

## Statements: final or not

A statement either **ends** the check for this packet, or it does **not** and lets the next rule run. This section lists both kinds.

### Verdict statements

A **verdict** is the shield's decision about a packet.

| Verdict | Effect | Ends the check? |
|---|---|---|
| `accept` | let the packet past **this hook** (later hooks still apply) | yes |
| `drop` | discard it silently: no reply, the sender waits for a timeout | yes |
| `reject` | discard it **and** send an error back (ICMP unreachable, or a TCP reset with `reject with tcp reset`), so the sender fails fast | yes |
| `queue` | hand the packet to a program outside the kernel through NFQUEUE | yes |
| `jump <chain>` | check `<chain>`, then come back here | no (comes back) |
| `goto <chain>` | check `<chain>`, do not come back | no (falls through to the base chain's policy) |
| `continue` | do nothing, move to the next rule | no |
| `return` | leave the current chain; in a base chain this means "apply the policy" | no |

`accept` is not "final for the whole firewall". It means *this chain on this hook is done with the packet*. A packet accepted at `prerouting` still faces the `input` chain.

`drop` against `reject` is a real design choice. `drop` lets the signal vanish, so your host looks dark and a port scanner has to wait for each timeout. `reject` bounces the signal back with a refusal, which is kinder to real clients that hit a closed port: they get "connection refused" at once instead of hanging.

### Statements that let the check carry on

These do something and then let the next rule run:

- `counter` counts the packets and bytes that reached this point.
- `log` writes to the kernel log (`log prefix "dropped: " level warn`). Limit its rate, or a flood of packets becomes a flood of log lines.
- `limit rate 10/second` works like a match: the rule only passes while traffic stays under the rate.
- `meta mark set 0x1` stamps a firewall mark on the packet, for routing by mark or for later rules.
- `ct mark set` stamps the connection, so the mark sticks to every later packet of that connection.

Because `counter` and `log` do not end the check, a common debugging trick is a `log` and `counter` rule *just above* a `drop`. Then you can see exactly what the `drop` is catching.

## See `drop` in action

Now watch a `drop` verdict make a port go dark on your playground. You need a listener for the shields to protect, and a base chain on the `input` hook.

### Start a listener and build the chain

<!-- astrona:playground:renew -->

Start a small web server on port 5000 in one SSH (Secure Shell, the sealed communications channel between ships) session (or add `&` to run it in the background):

```sh
python3 -m http.server 5000
```

In a second session, create the table and the base chain:

```sh
sudo nft add table inet filter
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'
```

### Drop the port and watch it go dark

Reach the server, add a `drop` rule for its port, and try again:

```sh
curl -sS --max-time 3 http://127.0.0.1:5000/ | head -c 40 ; echo
sudo nft add rule inet filter input tcp dport 5000 drop
curl -sS --max-time 3 http://127.0.0.1:5000/ ; echo "exit: $?"
```

The first `curl` prints the start of a directory listing. The second one stalls for three seconds, then fails:

```text
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN
curl: (28) Operation timed out after 3001 milliseconds
exit: 28
```

The rule matched every TCP (Transmission Control Protocol, a steady two-way conversation between programs) packet for port 5000 and dropped it. There was no refusal and no answer at all, which is exactly how `drop` differs from `reject`. Clean up when you are done:

```sh
sudo nft flush ruleset
```

## Common pitfalls

> [!WARNING]
> - **Expecting "or" inside one rule.** All matches in a rule must be true. For "port 80 or port 443" use a set, `{ 80, 443 }`, or two rules.
> - **Thinking `accept` is final everywhere.** It only ends the check for this chain on this hook. Another hook can still drop the packet.
> - **Logging without a rate limit.** A flood of dropped packets turns into a flood of log lines. Add `limit rate` to `log` rules.

> *A rule is matches then statements, and every match must be true. `accept`, `drop` and `reject` end the check; `counter` and `log` let it carry on.*
