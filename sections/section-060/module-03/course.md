# Active Socket Diagnostics (ss)

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-060/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-03/playground
> astrona destroy ss-socket-diagnostics-playground
> ```

A **socket** is the operating system's endpoint for a communication channel — a
TCP or UDP connection over IP, or a **Unix-domain** socket between processes on
the same machine. The kernel keeps a table of every one. **`ss`** ("socket
statistics") dumps that table. It answers questions like:

- What is listening on port 8080, and which process owns it?
- Is this backend actually accepting connections, or just meant to be?
- Why can a new server not bind — what already holds that port?
- How many connections are open, and in what state?

`ss` is the modern replacement for `netstat`: it reads the same kernel data
through a faster interface and has a real filter language. If you know
`netstat -tlnp`, `ss -tlnp` is the direct equivalent.

## Learning objectives

After this module you can:

- Explain what `ss` reports and how it differs from `netstat`.
- List listening TCP and UDP sockets with their owning process using
  `ss -tlnp` and `ss -ulnp`.
- Read the Local Address column and tell an all-addresses bind from a
  localhost-only one.
- Filter by connection state (`state listening`, `state established`,
  `state time-wait`) and by port or address with `ss` filter expressions.
- Inspect Unix-domain sockets with `ss -x`.
- Diagnose "address already in use" by finding the process holding a port, and
  decide what to do about it.

## Before you start

This module assumes you know what a TCP or UDP **port** is, what an IP address
is, and that a server "listens" on a port for clients to connect (the nginx
modules use this). You need a shell and `sudo`. Socket, connection state, and
Unix-domain socket are defined as they come up.

The playground is a single VM (`astrona ssh ss-socket-diagnostics-playground`)
pre-seeded so every `ss` view has something to show:

- TCP listeners on **`0.0.0.0:8080`** (all IPv4 addresses), **`127.0.0.1:9000`**
  (localhost only), and **`[::1]:8090`** (IPv6 loopback).
- A **UDP** listener on `:5514`.
- A **Unix-domain** listener at `/run/lab-app.sock`.
- One long-lived **established** TCP connection to `:9000`.

Each is a `lab-*` systemd service you can stop and start freely. `ss`, `socat`,
and `curl` are installed; `sudo` needs no password.

## Listening sockets and their owners

The most common `ss` invocation is `ss -tlnp`:

- `-t` — TCP.
- `-l` — listening sockets only. Without it, `ss` shows *non*-listening sockets
  (established connections and such); with `-a` it shows both.
- `-n` — numeric: do not translate `:80` to `http` or resolve addresses to
  names. Faster, and never ambiguous.
- `-p` — show the process (name, PID, file descriptor). Needs root to see
  processes owned by other users.

> [!TIP]
> **Try it — what is listening, and who owns it**
>
> ```sh
> sudo ss -tlnp
> ```
>
> Expect the seeded listeners plus `sshd`:
>
> ```text
> State   Recv-Q  Send-Q   Local Address:Port   Peer Address:Port  Process
> LISTEN  0       5        0.0.0.0:8080         0.0.0.0:*          users:(("python3",pid=812,fd=3))
> LISTEN  0       128      0.0.0.0:22           0.0.0.0:*          users:(("sshd",pid=701,fd=3))
> LISTEN  0       5        127.0.0.1:9000       0.0.0.0:*          users:(("python3",pid=815,fd=3))
> LISTEN  0       5        [::1]:8090           [::]:*             users:(("python3",pid=818,fd=3))
> ```
>
> The `Process` column ties each port to a PID. For a listener, `Send-Q` is the
> accept-queue size (the `listen()` backlog) and `Recv-Q` is how many completed
> connections are waiting to be `accept()`ed. Drop `sudo` and the `Process`
> column goes blank for anything you do not own.

## Reading the Local Address column

The address a socket is bound to decides *who can reach it*, and `ss` shows it
verbatim:

- **`0.0.0.0:8080`** (or `*:8080` without `-n`) — bound to **every IPv4
  address** on the host. Reachable from other machines, subject to the firewall.
- **`127.0.0.1:9000`** — bound to **loopback only**. Reachable from processes on
  this host and nothing else. A service bound here will refuse every remote
  client no matter what the firewall says.
- **`[::]:8090`** — every IPv6 address; **`[::1]:8090`** — IPv6 loopback only.
- **`192.168.1.10:5432`** — only that one interface address.

A listener you can see in `ss` is not automatically reachable: a `0.0.0.0` bind
still needs a firewall rule to let traffic in, and a `127.0.0.1` bind is
unreachable from off-box by design. "The service is up but nobody can connect"
is very often a `127.0.0.1` bind that should be `0.0.0.0`.

## Connections and their states

Drop `-l` and `ss` shows sockets that are *not* listening — mostly established
connections. Add a state filter to narrow it: `ss` understands
`state established`, `state listening`, `state time-wait`, `state close-wait`,
and the rest of the TCP state names.

> [!TIP]
> **Try it — the held connection**
>
> ```sh
> sudo ss -tnp state established
> ```
>
> Expect the seeded connection to `:9000`, shown from both ends:
>
> ```text
> State  Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
> ESTAB  0       0       127.0.0.1:9000      127.0.0.1:41522    users:(("python3",pid=815,fd=5))
> ESTAB  0       0       127.0.0.1:41522     127.0.0.1:9000     users:(("sleep",pid=820,fd=3))
> ```
>
> Two rows, one per side of the same connection: the server side on `:9000` and
> the client side on an ephemeral port (here held open by `sleep`). `Recv-Q`/`Send-Q` here are bytes queued
> but not yet read / not yet acknowledged — `0`/`0` on an idle connection.
> `sudo ss -tn state time-wait` will show a `TIME-WAIT` if you first run
> `curl -s http://127.0.0.1:8080/ >/dev/null`.

## UDP has no connection state

UDP is connectionless — there is no handshake and no `ESTAB`. `ss -u` shows UDP
sockets in state `UNCONN` (unconnected); `-l` still selects the ones bound and
waiting for datagrams.

> [!TIP]
> **Try it — the UDP listener**
>
> ```sh
> sudo ss -ulnp
> ```
>
> Expect one row for `:5514`:
>
> ```text
> State   Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
> UNCONN  0       0       0.0.0.0:5514        0.0.0.0:*          users:(("socat",pid=840,fd=5))
> ```
>
> `UNCONN`, not `LISTEN` — UDP has nothing to "listen" for in the TCP sense.
> There is no per-connection view for UDP because there are no connections.

## Unix-domain sockets

Processes on one host often talk over Unix-domain sockets instead of TCP — the
Docker daemon, `systemd`, D-Bus, many databases. They have a filesystem path
instead of an address:port. `ss -x` shows them.

> [!TIP]
> **Try it — local IPC endpoints**
>
> ```sh
> sudo ss -xlp | grep -E 'lab-app|systemd|Process'
> ```
>
> Expect the seeded socket alongside system ones:
>
> ```text
> Netid  State   Recv-Q  Send-Q  Local Address:Port        Peer Address:Port  Process
> u_str  LISTEN  0       128     /run/lab-app.sock 41200    * 0                users:(("socat",pid=845,fd=5))
> ```
>
> The "address" is `/run/lab-app.sock`. `u_str` is a stream Unix socket
> (`u_dgr` would be datagram). These never leave the machine, so a firewall does
> not apply to them.

## Filtering by port and address

`ss` takes a filter expression after the options. The building blocks:
`sport`/`dport` for the local/remote port, `src`/`dst` for the address, joined
with `and`/`or` and grouped with parentheses. Ports are written with a colon:
`sport = :9000`, not `sport = 9000`.

> [!TIP]
> **Try it — narrow to one port**
>
> ```sh
> sudo ss -tnp 'sport = :9000'
> sudo ss -tnp '( sport = :9000 or dport = :9000 )'
> ```
>
> The first shows sockets whose **local** port is 9000 (the listener and the
> server side of the connection); the second adds the client side, whose
> *destination* port is 9000:
>
> ```text
> LISTEN  0  5  127.0.0.1:9000    0.0.0.0:*
> ESTAB   0  0  127.0.0.1:9000    127.0.0.1:41522
> ESTAB   0  0  127.0.0.1:41522   127.0.0.1:9000
> ```
>
> Filter expressions are how you cut a busy `ss` dump down to the one
> conversation you care about — far quicker than piping to `grep`, and it
> understands ranges (`dport > :1024`) and negation (`dport != :22`).

## "Address already in use"

When a server fails to start with `bind: Address already in use`, something is
already holding that port. `ss` finds it:

> [!TIP]
> **Try it — find what holds a port**
>
> Try to start a second listener on 8080, which is taken:
>
> ```sh
> python3 -m http.server 8080
> ```
>
> ```text
> OSError: [Errno 98] Address already in use
> ```
>
> Then identify the holder:
>
> ```sh
> sudo ss -tlnp 'sport = :8080'
> ss -s
> ```
>
> ```text
> LISTEN  0  5  0.0.0.0:8080  0.0.0.0:*  users:(("python3",pid=812,fd=3))
> ```
>
> Now you know PID 812 (`lab-http-any`) owns it. **Then decide** — is that the
> service that is *supposed* to own 8080 (leave it), a stale process from a
> crashed run (stop it: `sudo systemctl stop lab-http-any`, or `kill` the PID),
> or should the new server use a different port? Killing whatever `ss` points at
> without checking what it is can take down a working service. `ss -s` gives the
> one-line totals — sockets per protocol and TCP state.

## Where this fits

`ss` reports what the kernel has, not what is reachable. Pair it with the other
layers: a service must **listen** (this module) *and* have a **firewall** rule
permitting the port (`nft` / `firewalld`, section-030) before a remote client
gets through — `ss` shows the first half, `curl`/`nmap` from another host tests
the whole path. It also pairs with the reverse-proxy and load-balancer modules
("is the backend on `127.0.0.1:9001` actually up?") and with SSH hardening
("what is this box exposing?"). On systemd machines a `.socket` unit can hold a
listener with no process attached until the first connection — `ss` will show
the socket owned by `systemd` (pid 1).

> [!WARNING]
> **Common pitfalls**
>
> - **No `-n`.** `ss` resolves `:443` to `https`, `:22` to `ssh`, and addresses
>   to hostnames — slow on a bad DNS path and easy to misread. Add `-n` for
>   diagnostics.
> - **No `sudo` with `-p`.** The `Process` column is blank for sockets owned by
>   other users. Run `ss` as root when you need the owner.
> - **Forgetting `-l` semantics.** Plain `ss -t` shows established sockets, not
>   listeners. Use `-l` for listeners, `-a` for both.
> - **Reading a listener as "reachable".** A `0.0.0.0` bind still needs a
>   firewall rule; a `127.0.0.1` bind is unreachable from other hosts on
>   purpose. `ss` shows the bind, not the path.
> - **Many `CLOSE-WAIT` sockets.** That means the local application is not
>   closing connections the peer already closed — an application bug, not a
>   network fault.
> - **Killing the PID from `ss -p` blindly.** Confirm what the process is first;
>   it may be the service that is meant to own the port.
> - **`sport = 9000` without the colon.** `ss` filter ports need `:` —
>   `sport = :9000`.
