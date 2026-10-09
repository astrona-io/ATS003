# Listening Sockets And Who Owns Them

Astronaut, before you can ask "why can nobody reach this service?", you need to know whether anything is waiting for the call at all. This part explains what a socket is, how to read the `ss` roster, and what the bind address says about who can reach a service.

## What a socket is and what `ss` shows

A **socket** is the operating system's endpoint for a communication channel: an open radio channel. It can be a TCP (Transmission Control Protocol, a channel where both sides confirm every signal) or UDP (User Datagram Protocol, single signal bursts with no confirmation) connection over IP, or a **Unix-domain** socket between processes on the same machine. The kernel keeps a table of every one.

### The questions `ss` answers

**`ss`** ("socket statistics") prints that table. It answers questions like:

- What is listening on port 8080, and which process owns it?
- Is this backend really accepting connections, or only meant to be?
- Why can a new server not bind: what already holds that port?
- How many connections are open, and in what state?

`ss` is the modern replacement for `netstat`. It reads the same kernel data through a faster interface and has a real filter language. If you know `netstat -tlnp`, `ss -tlnp` is the direct equivalent.

### What `ss` does not tell you

`ss` reports what the kernel has, not what is reachable. A service must **listen** *and* have a **firewall** rule that lets the port through before a remote client gets in. `ss` shows the first half; `curl` (or `nmap`) from another host tests the whole path.

It is also the quick answer to "is the backend on `127.0.0.1:9001` really up?" behind a reverse proxy, and to "what is this server exposing?" when you harden it. On systemd machines a `.socket` unit can hold a listener with no service process attached until the first connection arrives. `ss` then shows the socket owned by `systemd` (process ID 1).

## Reading `ss`

`ss` options fall into three groups, plus an optional filter expression at the end. Knowing the groups lets you build the right command without a manual.

### The option groups

| Group | Flags | Effect |
|---|---|---|
| **Which sockets** | `-t` TCP, `-u` UDP, `-x` Unix; `-l` listening only, `-a` all | pick the family and whether to include non-listeners |
| **What to show** | `-n` numeric (no port/host name lookups), `-p` owning process, `-e` extended, `-o` timers | shape each row |
| **Summary** | `-s` | one-line totals per protocol and TCP state, instead of the table |

A simple way to remember it: choose a **protocol letter**, add **`-l`** for listeners, and add **`-n -p`** so you get numbers and a process ID. `ss -tlnp` is the everyday command. Everything after the options is a filter.

## Listening sockets and their owners

The most common `ss` command is `ss -tlnp`. Without `-l` it shows sockets that are *not* listening (established connections and others). `-p` needs root to see processes that belong to other users.

### What is listening, and who owns it

<!-- astrona:playground:renew -->

List the listening TCP sockets with their owners:

```sh
sudo ss -tlnp
```

Expect the seeded listeners plus `sshd`:

```text
State   Recv-Q  Send-Q   Local Address:Port   Peer Address:Port  Process
LISTEN  0       5        0.0.0.0:8080         0.0.0.0:*          users:(("python3",pid=812,fd=3))
LISTEN  0       128      0.0.0.0:22           0.0.0.0:*          users:(("sshd",pid=701,fd=3))
LISTEN  0       5        127.0.0.1:9000       0.0.0.0:*          users:(("python3",pid=815,fd=3))
LISTEN  0       5        [::1]:8090           [::]:*             users:(("python3",pid=818,fd=3))
```

The `Process` column ties each port to a process ID (its crew badge number). For a listener, `Send-Q` is the size of the accept queue (the `listen()` backlog), and `Recv-Q` is how many finished connections are waiting to be `accept()`ed. Run it without `sudo` and the `Process` column goes blank for anything you do not own.

## Reading the Local Address column

The address a socket is bound to decides *who can reach it*, and `ss` shows it exactly. This column answers most "why can nobody connect?" questions.

### What each bind means

- **`0.0.0.0:8080`** (or `*:8080` without `-n`): bound to **every IPv4 address** on the host. Other machines can reach it, if the firewall allows.
- **`127.0.0.1:9000`**: bound to **loopback only**, the ship's internal intercom. Only processes on this host can reach it. A service bound here refuses every remote client, whatever the firewall says.
- **`[::]:8090`**: every IPv6 address. **`[::1]:8090`**: IPv6 loopback only.
- **`192.168.1.10:5432`**: only that one interface address.

A listener you see in `ss` is not automatically reachable. A `0.0.0.0` bind still needs a firewall rule to let traffic in, and a `127.0.0.1` bind cannot be reached from another machine by design. "The service is up but nobody can connect" is very often a `127.0.0.1` bind that should be `0.0.0.0`.

## Common pitfalls

> [!WARNING]
> - **No `-n`.** `ss` turns `:443` into `https`, `:22` into `ssh`, and addresses into host names. That is slow on a bad DNS path and easy to misread. Add `-n` for diagnostics.
> - **No `sudo` with `-p`.** The `Process` column is blank for sockets owned by other users. Run `ss` as root when you need the owner.
> - **Reading a listener as "reachable".** A `0.0.0.0` bind still needs a firewall rule; a `127.0.0.1` bind cannot be reached from other hosts on purpose. `ss` shows the bind, not the path.
