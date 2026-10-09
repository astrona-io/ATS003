# Active Socket Diagnostics (ss)

Astronaut, every open radio channel on your ship is listed somewhere in the ship's core. **`ss`** prints that roster: which channels are open, which wait for a call, and which crew member holds each one. When a service "should be up" but nobody can reach it, this roster is where you look first.

## Learning objectives

After this module you can:

- Explain what `ss` reports and how it differs from `netstat`.
- List listening TCP (Transmission Control Protocol, a channel where both sides confirm every signal) and UDP (User Datagram Protocol, single signal bursts with no confirmation) sockets with their owning process using `ss -tlnp` and `ss -ulnp`.
- Read the Local Address column and tell an all-addresses bind from a localhost-only one.
- Filter by connection state (`state listening`, `state established`, `state time-wait`) and by port or address with `ss` filter expressions.
- Inspect Unix-domain sockets with `ss -x`.
- Diagnose "address already in use" by finding the process holding a port, and decide what to do about it.

## Before you start

A short pre-flight check: the knowledge this module expects, and what is waiting in your playground.

### What you should already know

- **Ports and addresses.** What an IP (Internet Protocol) address is (the ship's call sign on the space lanes), what a TCP or UDP **port** is, and that a server "listens" on a port for clients to connect.
- **The shell.** You can open a shell and use `sudo`. Socket, connection state and Unix-domain socket are explained in the parts.

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine. Open a shell on it with `astrona ssh ss-socket-diagnostics-playground`. It is seeded so every `ss` view has something to show, one systemd service per socket:

| Socket | Service | Shows |
| --- | --- | --- |
| TCP `0.0.0.0:8080` | `lab-http-any` | listener on **all** IPv4 addresses |
| TCP `127.0.0.1:9000` | `lab-http-local` | listener bound to **localhost only** |
| TCP `[::1]:8090` | `lab-http-v6` | IPv6 loopback listener |
| UDP `0.0.0.0:5514` | `lab-udp` | a UDP listener (no connection state) |
| UNIX `/run/lab-app.sock` | `lab-unix` | a Unix-domain stream listener |
| one ESTABLISHED TCP pair on `127.0.0.1:9000` | `lab-estab` | a live connection to filter for |

You can stop and start each `lab-*` service freely. `ss`, `socat`, `python3` and `curl` are installed, and `sudo` needs no password.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Listening Sockets And Who Owns Them](./course-01-listening-sockets.md): what a socket is, how to read `ss`, and what the bind address tells you.
2. [Connections, UDP And Unix Sockets](./course-02-connections-udp-unix.md): established connections and their states, connectionless UDP, and local Unix-domain sockets.
3. [Filter And Find The Port Holder](./course-03-filter-and-find-the-holder.md): cut the list down with filter expressions and solve "address already in use".
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, a self-check and cleanup.

## Why this matters

"The service is up but nobody can connect" is one of the most common problems on any server, and on the exam. `ss` tells you in seconds whether anything listens, on which address, and which process owns it. That answer decides whether you look at the application, its bind address, or the firewall next.
