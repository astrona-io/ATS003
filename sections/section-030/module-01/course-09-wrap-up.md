# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part of this module and its mission. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about programming the ship's shields by hand with nftables, from an empty ruleset to a ruleset that survives a reboot.

**From [Netfilter And The Packet Path](./course-01-netfilter-and-packet-flow.md):**

- Netfilter is the framework in the kernel; nftables is one tool that registers rules on it.
- The five hooks are `prerouting`, `input`, `forward`, `output` and `postrouting`. The routing decision after `prerouting` sends a packet to `input` (for this host) or `forward` (passing through).
- Callbacks on a hook run lowest priority first. `filter` is 0, `dstnat` is -100, connection tracking is -200.

**From [Tables And Address Families](./course-02-tables-and-families.md):**

- A table is a namespace tied to one family. On its own it filters nothing.
- `inet` covers IPv4 and IPv6 in one rule list; `ip` sees only IPv4.
- nftables starts empty: `sudo nft list ruleset` prints nothing on a fresh machine.

**From [Chains, Hooks, Priority And Policy](./course-03-chains-hooks-priority.md):**

- Only a base chain, with `type`, `hook`, `priority` and `policy`, receives packets. A regular chain is reached with `jump` (comes back) or `goto` (does not).
- The policy is the verdict for packets no rule matched. `policy drop` without an SSH (Secure Shell, the sealed communications channel between ships) accept locks you out.

**From [Rules: Matches And Verdicts](./course-04-rules-matches-verdicts.md):**

- All matches in a rule must be true. `accept`, `drop` and `reject` end the check; `counter` and `log` do not.
- `drop` lets a signal vanish (the sender times out); `reject` bounces it back with a refusal.

**From [Rule Order, Handles And Redirects](./course-05-rule-order-handles-redirects.md):**

- The first final verdict wins, so put the specific `accept` above the broad `drop`.
- Rules are edited and deleted by handle (`nft -a list ruleset`); `insert` puts a rule at the front.
- `counter` shows whether a rule matches without blocking anything.
- A port redirect lives in a `type nat` chain on `prerouting`, for example `tcp dport 8080 redirect to :5000`.

**From [Connection Tracking](./course-06-connection-tracking.md):**

- The tracker stamps every packet as `new`, `established`, `related`, `invalid` or `untracked`.
- `ct state established,related accept` and `ct state invalid drop` belong near the top of every `input` chain.

**From [Sets And Maps](./course-07-sets-and-maps.md):**

- A named set lets one rule match many values, and you change it with `add element` without editing rules.
- A verdict map (`vmap`) picks a verdict per key in one lookup.

**From [Persistence And Operating A Ruleset](./course-08-persistence-and-operations.md):**

- `nft` changes vanish on reboot. `/etc/nftables.conf` plus an enabled `nftables.service` brings them back.
- `nft -f` loads a whole file in one transaction; `nft -c -f` only checks it.
- On a host run by `firewalld` or `ufw`, change the firewall with that tool, not with `nft`.

## Your missions

You proved the skills in a graded mission right after the part that taught them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Packet Filtering with nftables Lab](./labs/lab-01/README.md) | Rule Order, Handles And Redirects | build filter and NAT tables with a drop, a redirect, a source-limited port and an outgoing block |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. A machine routes traffic for other hosts. Which hook does a packet passing through it reach after the routing decision?</summary>

`forward`. `input` only sees packets for this host, and `output` only sees packets this host sends.
</details>

<details>
<summary>2. You wrote careful rules in an <code>ip</code> table. Is the host protected over IPv6?</summary>

No. An `ip` table only sees IPv4 packets. Use an `inet` table so one rule list covers both.
</details>

<details>
<summary>3. You put rules in a chain called <code>tcp_in</code>, but they never match. What do you check first?</summary>

Whether any base chain does `jump tcp_in` or `goto tcp_in`. A regular chain has no hook, so no packet reaches it on its own.
</details>

<details>
<summary>4. A chain has <code>tcp dport 6002 drop</code> above <code>ip saddr 192.168.80.10 tcp dport 6002 accept</code>. What happens to traffic from 192.168.80.10 on port 6002?</summary>

It is dropped. The check stops at the first final verdict, so the `accept` below is never reached. Put the `accept` first.
</details>

<details>
<summary>5. What is the difference between <code>drop</code> and <code>reject</code> for the sender?</summary>

With `drop` the sender gets no answer and waits for a timeout. With `reject` it gets an error back at once, such as "connection refused".
</details>

<details>
<summary>6. Which chain type and hook do you need for <code>redirect to :6001</code>?</summary>

A chain of `type nat` on the `prerouting` hook, usually at priority `-100` (`dstnat`).
</details>

<details>
<summary>7. You built a ruleset with <code>nft</code> commands and rebooted. Where did it go?</summary>

It is gone. `nft` changes live only in the running kernel. Save them to `/etc/nftables.conf` and enable `nftables.service`.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy nftables-filtering-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-031
```

Then run `astrona list` again and check that neither name is listed any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.

> *The shields start empty. You build a table, put base chains on the right hooks, order the rules so the right one wins, and save the result so it survives a reboot.*
