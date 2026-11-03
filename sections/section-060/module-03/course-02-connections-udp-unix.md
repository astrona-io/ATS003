# Connections, UDP And Unix Sockets

Astronaut, a listening channel is only half the roster. This part shows the channels that are already in a conversation, the UDP (User Datagram Protocol, single signal bursts with no confirmation) channels that never hold one, and the Unix-domain sockets that never leave the ship.

## Connections and their states

Drop `-l` and `ss` shows sockets that are *not* listening, mostly established connections. A state filter narrows the list to the conversations you care about.

### State names

`ss` understands `state established`, `state listening`, `state time-wait`, `state close-wait` and the rest of the TCP (Transmission Control Protocol, a channel where both sides confirm every signal) state names. Add one after the options to keep only sockets in that state.

### The held connection

<!-- astrona:playground:renew -->

List the established TCP connections with their owners:

```sh
sudo ss -tnp state established
```

Expect the seeded connection to `:9000`, shown from both ends:

```text
State  Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
ESTAB  0       0       127.0.0.1:9000      127.0.0.1:41522    users:(("python3",pid=815,fd=5))
ESTAB  0       0       127.0.0.1:41522     127.0.0.1:9000     users:(("sleep",pid=820,fd=3))
```

There are two rows, one per side of the same connection. One is the server side on `:9000`; the other is the client side on a short-lived (ephemeral) port, here held open by `sleep`. On a connection, `Recv-Q` and `Send-Q` count bytes not yet read and bytes not yet acknowledged. An idle connection shows `0` and `0`.

To see a `TIME-WAIT` socket, first run `curl -s http://127.0.0.1:8080/ >/dev/null`, then `sudo ss -tn state time-wait`.

## UDP has no connection state

UDP is connectionless: there is no handshake and no `ESTAB`. A UDP channel just sends and receives single bursts.

### How UDP sockets look

`ss -u` shows UDP sockets in state `UNCONN` (unconnected). `-l` still selects the ones bound and waiting for datagrams.

### The UDP listener

List the listening UDP sockets:

```sh
sudo ss -ulnp
```

Expect one row for `:5514`:

```text
State   Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
UNCONN  0       0       0.0.0.0:5514        0.0.0.0:*          users:(("socat",pid=840,fd=5))
```

The state is `UNCONN`, not `LISTEN`: UDP has nothing to "listen" for in the TCP sense. There is no per-connection view for UDP, because there are no connections.

## Unix-domain sockets

Processes on one host often talk over Unix-domain sockets instead of TCP: the Docker daemon, `systemd`, D-Bus and many databases do. They have a file system path instead of an address and port.

### Local endpoints with `ss -x`

List the listening Unix sockets and keep the interesting lines:

```sh
sudo ss -xlp | grep -E 'lab-app|systemd|Process'
```

Expect the seeded socket among the system ones:

```text
Netid  State   Recv-Q  Send-Q  Local Address:Port        Peer Address:Port  Process
u_str  LISTEN  0       128     /run/lab-app.sock 41200    * 0                users:(("socat",pid=845,fd=5))
```

The "address" is `/run/lab-app.sock`. `u_str` is a stream Unix socket; `u_dgr` would be a datagram one. These never leave the machine, so a firewall does not apply to them.

## Common pitfalls

> [!WARNING]
> - **Forgetting what `-l` does.** Plain `ss -t` shows established sockets, not listeners. Use `-l` for listeners and `-a` for both.
> - **Many `CLOSE-WAIT` sockets.** The local application is not closing connections the other side already closed. That is an application bug, not a network fault.
> - **Looking for `LISTEN` on UDP.** UDP sockets show `UNCONN`. Use `ss -ulnp` and read the port.
