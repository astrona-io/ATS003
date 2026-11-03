# Filter And Find The Port Holder

Astronaut, on a busy ship the roster is long. This part teaches you to cut it down to one conversation with a filter expression, and to use that skill on a classic failure: a server that cannot start because its channel is already taken.

## Filtering by port and address

`ss` takes a filter expression after the options. It is quicker than piping to `grep`, and it understands ports, addresses, ranges and negation.

### The building blocks

- `sport` and `dport` match the local (source) and remote (destination) port.
- `src` and `dst` match the address.
- `and` and `or` join conditions; parentheses group them.

Ports are written with a colon: `sport = :9000`, not `sport = 9000`.

### Narrow to one port

<!-- astrona:playground:renew -->

Show the sockets on port 9000, first by local port only, then from both sides:

```sh
sudo ss -tnp 'sport = :9000'
sudo ss -tnp '( sport = :9000 or dport = :9000 )'
```

The first command shows sockets whose **local** port is 9000: the listener and the server side of the connection. The second adds the client side, whose *destination* port is 9000:

```text
LISTEN  0  5  127.0.0.1:9000    0.0.0.0:*
ESTAB   0  0  127.0.0.1:9000    127.0.0.1:41522
ESTAB   0  0  127.0.0.1:41522   127.0.0.1:9000
```

Filter expressions also understand ranges (`dport > :1024`) and negation (`dport != :22`). Quote the whole expression so the shell leaves the parentheses alone.

## "Address already in use"

When a server fails to start with `bind: Address already in use`, something already holds that port. `ss` finds out what.

### Find what holds a port

Try to start a second listener on 8080, which is already taken:

```sh
python3 -m http.server 8080
```

```text
OSError: [Errno 98] Address already in use
```

Then find the holder, and print the one-line totals:

```sh
sudo ss -tlnp 'sport = :8080'
ss -s
```

```text
LISTEN  0  5  0.0.0.0:8080  0.0.0.0:*  users:(("python3",pid=812,fd=3))
```

Now you know process 812 (`lab-http-any`) owns the port. `ss -s` gives the totals: sockets per protocol and per TCP (Transmission Control Protocol, a channel where both sides confirm every signal) state.

### Then decide

Knowing the holder is not the end. Ask what it is before you act:

- Is it the service that is *supposed* to own 8080? Leave it alone.
- Is it a stale process from a crashed run? Stop it with `sudo systemctl stop lab-http-any`, or `kill` the process ID.
- Should the new server use a different port instead?

Killing whatever `ss` points at without checking can take down a working service.

## Common pitfalls

> [!WARNING]
> - **`sport = 9000` without the colon.** `ss` filter ports need `:`, as in `sport = :9000`.
> - **Unquoted filter expressions.** The shell reads the parentheses before `ss` sees them. Quote the whole expression.
> - **Killing the process from `ss -p` blindly.** Check what the process is first; it may be the service that is meant to own the port.

## Your mission: Active Socket Diagnostics (ss) Lab

You can now find what listens on a port, read its bind address, and narrow `ss` to one port. The graded mission gives you a web service that clients cannot reach: you prove with `ss` that it listens on a reachable address, then find and remove the firewall rule (an nftables rule, part of the ship's shields) that silently drops its traffic, and prove it answers with `curl`.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ss-socket-diagnostics-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-03/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-060/module-03/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-063
astrona start ss-socket-diagnostics-playground
```
