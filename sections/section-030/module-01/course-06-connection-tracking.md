# Connection Tracking

Astronaut, so far the shields judged every signal burst on its own. Real firewalls do not work like that. They remember which conversations are already in progress, so one rule can let in all the replies.

That memory is called **connection tracking**, and it is what makes a "deny everything by default" firewall practical. This part shows how it works and the two rules almost every real ruleset starts with.

## How the kernel tracks connections

Connection tracking runs in the kernel whether or not you write a rule for it. This section shows what it records and the states it gives each packet.

### The shield's memory

The kernel's **conntrack** subsystem watches traffic and builds a table of **connections**. It tracks TCP (Transmission Control Protocol, a steady two-way conversation between programs) conversations, and also UDP exchanges and ICMP echo pairs (ping and its reply). It sits on `prerouting` and `output` at priority **-200**. So by the time a `filter` chain at priority 0 runs, every packet is already stamped with the state of the connection it belongs to.

A connection is identified by a **tuple**: source address, destination address, protocol, and for TCP and UDP the source and destination ports. The tracker also keeps the reversed tuple for the reply direction. When it sees a packet, it looks up the tuple and gives the packet a state.

### The states

| `ct state` | Meaning |
|---|---|
| `new` | the first packet of a connection the tracker has not seen before |
| `established` | a packet of a connection that has seen traffic in **both** directions |
| `related` | a **new** connection the tracker knows was started by an existing one, such as an FTP data channel or an ICMP error about a tracked flow |
| `invalid` | a packet the tracker cannot tie to any connection (a bad TCP state, out of sequence); almost always safe to `drop` |
| `untracked` | a packet you deliberately took out of tracking with `notrack` in a `raw` (-300) chain |

FTP, the File Transfer Protocol, is an old file-copy protocol that opens a second connection for the data.

## The two rules almost every ruleset starts with

With the tracker doing the remembering, two short rules handle most of the traffic on a host. This section shows them and why they belong near the top.

### Accept the known, drop the broken

```sh
sudo nft add rule inet filter input ct state established,related accept
sudo nft add rule inet filter input ct state invalid drop
```

The first rule is the reason "default deny" works. You accept the *first* packet of each connection you want (SSH (Secure Shell, the sealed communications channel between ships), web, and so on) with specific rules. Every later packet of that connection, and every reply coming *in* for a connection your own ship started, matches `established` and is accepted by this one line.

Without it, `policy drop` on `input` would also drop the replies to connections your own machine opened.

### Put them near the top

Place both rules **near the top** of the `input` chain, right after `iif "lo" accept`. They handle most of the packets, so matching them early is also the fast path.

## Watch a connection get tracked

Now build a small default-deny chain on your playground and watch the tracker carry the replies through it.

### Build a default-deny input chain

<!-- astrona:playground:renew -->

This chain only lets in the intercom, established traffic and SSH:

```sh
sudo nft flush ruleset
sudo nft add table inet filter
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy drop ; }'
sudo nft add rule inet filter input iif "lo" accept
sudo nft add rule inet filter input ct state established,related counter accept
sudo nft add rule inet filter input tcp dport 22 accept
```

Your SSH session stays up. Its packets match `established` (or `tcp dport 22`) before the policy is reached.

### See the tracker record a connection

Start an outgoing connection and list what the tracker holds:

```sh
curl -sS --max-time 5 http://192.168.80.10/ >/dev/null &
sudo conntrack -L 2>/dev/null | grep -E 'tcp .* (SYN_SENT|ESTABLISHED)' | head
```

Look for a line that shows the tracked TCP tuple in both directions. The reply packets coming back in are `established`, so the counter on that rule goes up, even though no rule names the source port `curl` picked.

Run `sudo nft list chain inet filter input` again and check that the `established,related` counter moved. Clean up with `sudo nft flush ruleset`.

## Skipping the tracker, and helpers

Tracking every packet costs a little work. For a few special cases you can switch it off, or teach the tracker about a protocol. Both are rare, but you should recognise them:

- A rule with `ct state untracked` only matches packets you sent through `notrack` in a `raw` (priority -300) chain. People do this for very busy flows, such as a DNS server (the galaxy-wide directory of call signs), where tracking every packet is not worth the cost. Untracked packets get no `established` shortcut, so you filter them without state.
- **Conntrack helpers** (`ct helper set "ftp"`) teach the tracker to read a protocol's control channel and mark its data channel `related`. Helpers look inside the packet contents, so they are a security risk. Turn on only the ones you need, and only on the port that needs them.

## Common pitfalls

> [!WARNING]
> - **`policy drop` without `ct state established,related accept`.** Replies to connections your own machine opened are dropped too, and your SSH session can freeze.
> - **Forgetting `ct state invalid drop`.** Without it, out-of-state packets fall through to your general rules, and some of them may be accepted.
> - **Putting the state rules at the bottom.** They match most packets, so place them right after `iif "lo" accept`.

> *Connection tracking lets one `ct state established,related accept` rule cover the replies for every connection. That is what makes a default-deny firewall practical.*
