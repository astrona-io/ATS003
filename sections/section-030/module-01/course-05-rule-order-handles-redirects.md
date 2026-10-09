# Rule Order, Handles And Redirects

Astronaut, a checkpoint reads its lines from the top down and stops at the first final verdict. So the order of your rules decides everything. This part shows why, how to edit a ruleset that has no line numbers, how to count matches without blocking anything, how to allow one source and deny the rest, and how to send one radio channel to another with a port redirect.

## Rule order is the whole game

Rules in a chain run **top to bottom**. The first verdict that ends the check wins, and the kernel stops reading. Everything below follows from that one fact.

### Specific first, broad last

- A broad `drop` placed above a specific `accept` for the same packet turns the `accept` into **dead code**: it is never reached.
- So `accept` the specific, trusted thing first, and `drop` the broad rest after it.

## Edit a ruleset with no line numbers

You cannot say "delete rule 3" in nftables, because rules have no line numbers. This section shows what they have instead, and the commands that place a new rule exactly where you want it.

### Handles

To change or delete a rule you use its **handle**: a whole number the kernel gives each rule when it is created. It stays the same for the life of that rule. `nft -a` ("all") prints the handles.

### Set up a drop rule to work with

<!-- astrona:playground:renew -->

Start a small web server on port 5000 in one SSH (Secure Shell, the sealed communications channel between ships) session (or add `&` to run it in the background):

```sh
python3 -m http.server 5000
```

In a second session, build a table and a base chain on the `input` hook, and drop the port:

```sh
sudo nft add table inet filter
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'
sudo nft add rule inet filter input tcp dport 5000 drop
```

### Find a rule's handle and delete only that rule

List the ruleset with handles:

```sh
sudo nft -a list ruleset
```

The drop rule carries a handle:

```text
table inet filter {
	chain input { # handle 1
		type filter hook input priority filter; policy accept;
		tcp dport 5000 drop # handle 4
	}
}
```

Delete it by that handle (use the number you actually see), and check that the port answers again:

```sh
sudo nft delete rule inet filter input handle 4
curl -sS --max-time 3 http://127.0.0.1:5000/ | head -c 40 ; echo
```

The `curl` prints the start of the directory listing again. The kernel hands out handles, and they do **not** count up one by one, so yours will be different.

### `add`, `insert` and position

These commands decide where a new rule lands:

- `nft add rule … input tcp dport 5000 drop` **appends** the rule to the end of the chain.
- `nft insert rule … input tcp dport 22 accept` puts it at the **front** (position 0).
- `nft add rule … input position 4 tcp dport 80 accept` inserts it **after** the rule with handle 4.
- `nft insert rule … input position 4 …` inserts it **before** the rule with handle 4.
- `nft replace rule … input handle 4 tcp dport 5000 counter drop` swaps the rule at handle 4 for new text and keeps the handle.

## Count without blocking

On its own, `counter` is not a verdict. It records matches and the check carries on. It is the simplest way to answer "is this rule matching anything?"

### Count packets to a port

With the web server on port 5000 still running, add a counting rule and send two requests:

```sh
sudo nft add rule inet filter input tcp dport 5000 counter
curl -sS --max-time 3 http://127.0.0.1:5000/ >/dev/null
curl -sS --max-time 3 http://127.0.0.1:5000/ >/dev/null
sudo nft list ruleset
```

The rule now shows totals above zero:

```text
tcp dport 5000 counter packets 12 bytes 760
```

The traffic still went through, because `counter` has no `accept` or `drop`, but the rule shows it matched. The exact counts depend on how much the client and the server sent each other.

## Allow one source, deny the rest

All matches in a rule must be true, so `ip saddr X tcp dport P accept` only fires for that source on that port. The blanket `drop` must come **after** it. Here you see both outcomes on the same port.

### Add the two rules in the right order

```sh
sudo nft add rule inet filter input ip saddr 192.168.80.10 tcp dport 6002 accept
sudo nft add rule inet filter input tcp dport 6002 drop
```

Start a listener on port 6002 in another session. `python3 -m http.server 6002` listens on every interface:

```sh
python3 -m http.server 6002
```

### Same port, two sources, two outcomes

Reach the port twice: once with the source address `192.168.80.10` (the practice antenna), once from loopback:

```sh
curl -sS --max-time 3 --interface 192.168.80.10 http://192.168.80.10:6002/ | head -c 40 ; echo
curl -sS --max-time 3 http://127.0.0.1:6002/ ; echo "exit: $?"
```

The first request succeeds and the second one times out:

```text
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN
curl: (28) Operation timed out after 3001 milliseconds
exit: 28
```

The first request came from `192.168.80.10`, so it hit the `accept` and stopped there. The second came from `127.0.0.1`, missed the `accept`, and fell through to the `drop`. Swap the order of the two rules and **both** requests are dropped, because the `accept` is never reached.

## Redirect a port with a `nat` chain

Sometimes a program listens on one radio channel, but clients call on another. A **port redirect** fixes that without touching the program: the shields re-route the incoming signal to a different channel on the same ship.

### Where a redirect lives

A redirect rewrites the packet's destination, so it needs a chain of `type nat`, not `type filter`. Destination rewriting happens on the `prerouting` hook, before the routing decision, at the `dstnat` priority (-100). The rewrite is done by the kernel's address translation code; connection tracking remembers it and applies it to every later packet of the same connection.

Many people keep these rules in their own table of the `ip` family, often called `nat`.

### Build a redirect

This sends TCP (Transmission Control Protocol, a steady two-way conversation between programs) traffic that arrives for port 8080 to port 5000 on this same host:

```sh
sudo nft add table ip nat
sudo nft add chain ip nat prerouting '{ type nat hook prerouting priority -100 ; policy accept ; }'
sudo nft add rule ip nat prerouting tcp dport 8080 redirect to :5000
```

Then check the result:

```sh
sudo nft list chain ip nat prerouting
```

Look for the chain line with `type nat hook prerouting` and the rule `tcp dport 8080 redirect to :5000`. The colon before the port number is part of the syntax. A redirect only does something useful when a program is listening on the target port, so check that with `sudo ss -tulpn`.

`prerouting` only sees packets that *arrive* on an interface. A `curl` to `127.0.0.1` from the same machine is sent by a local program, so it takes the `output` path and does not pass this chain.

Clean up when you are done:

```sh
sudo nft flush ruleset
```

## Common pitfalls

> [!WARNING]
> - **Rule order.** The check stops at the first `drop` or `accept`. An `accept` placed after a broader `drop` is dead code.
> - **Expecting line numbers.** Rules are edited and deleted by **handle** (`nft -a list ruleset`), not by position and not by typing the rule text again.
> - **A redirect in a `filter` chain.** `redirect` only works in a chain of `type nat`, on the `prerouting` hook for incoming traffic.
> - **Writing the redirect port without the colon.** The rule reads `redirect to :5000`.

> *The first final verdict in a chain wins, so accept the specific trusted case before the broad drop, and edit by handle, not by position.*

## Your mission: Packet Filtering with nftables Lab

You can now build tables and chains on the right hooks, order rules so the right one wins, and redirect a port with a `nat` chain. Now prove it in a graded mission: build a filter table and a NAT table on an empty ruleset, with drops, a redirect, a source-limited port and an outgoing block.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop nftables-filtering-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-030/module-01/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-031
astrona start nftables-filtering-playground
```
