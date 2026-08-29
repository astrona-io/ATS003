# Overview: PLAYGROUND — Active Socket Diagnostics (ss) (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh ss-socket-diagnostics-playground`.
- `ss` (from `iproute2`), `socat`, `python3`, `curl`. Password-less `sudo`.
- A spread of sockets already running, one systemd service each:

| Socket | Service | Shows |
| --- | --- | --- |
| TCP `0.0.0.0:8080` | `lab-http-any` | listener on **all** IPv4 addresses |
| TCP `127.0.0.1:9000` | `lab-http-local` | listener bound to **localhost only** |
| TCP `[::1]:8090` | `lab-http-v6` | IPv6 loopback listener |
| UDP `0.0.0.0:5514` | `lab-udp` | a UDP listener (no connection state) |
| UNIX `/run/lab-app.sock` | `lab-unix` | a Unix-domain stream listener |
| one ESTABLISHED TCP pair on `127.0.0.1:9000` | `lab-estab` | a live connection to filter for |

## Things to try

- **Listening TCP with owners.** `sudo ss -tlnp` — `-t` TCP, `-l` listening,
  `-n` numeric (no port-name lookup), `-p` process. Note `-p` needs root for
  other users' processes.
- **Read the Local Address column.** `0.0.0.0:8080` and `*:8080` mean all IPv4;
  `127.0.0.1:9000` means only local clients can reach it; `[::1]:8090` is IPv6
  loopback. `[::]:*` would be all IPv6.
- **Everything, not just listeners.** `sudo ss -tnp` (drop `-l`) — adds
  connections in other states. `sudo ss -tanp` includes listeners too.
- **Filter by state.** `sudo ss -tnp state established`,
  `... state listening`, `... state time-wait`. Generate a `TIME-WAIT` with
  `curl -s http://127.0.0.1:8080/ >/dev/null` then look again quickly.
- **UDP.** `sudo ss -ulnp` — the `:5514` listener. UDP has no connection state,
  so there is no `ESTAB`/`LISTEN` distinction the way TCP has.
- **Unix sockets.** `sudo ss -xlp` — `/run/lab-app.sock` plus the system's own
  (`systemd`, `dbus`, journald).
- **Port and address filters.** `sudo ss -tn 'sport = :9000'`,
  `sudo ss -tn 'dport = :9000'`,
  `sudo ss -tn '( sport = :9000 or dport = :9000 )'`,
  `sudo ss -tn 'dst 127.0.0.1'`.
- **Summary.** `ss -s` — totals per protocol and TCP state.
- **The classic "address already in use".** Try to start another listener on a
  taken port: `python3 -m http.server 8080` — it fails; then
  `sudo ss -tlnp 'sport = :8080'` names the process holding it.
- **Timers and detail.** `sudo ss -tnpo` (`-o` shows timers),
  `sudo ss -tnpi` (`-i` shows TCP internals: `rtt`, `cwnd`).
- **Compare with the old tool.** `netstat -tlnp` if installed — `ss` is its
  faster replacement and reads the same kernel data.

## What this sandbox does not set up

- **Remote connections.** Everything is on `localhost`; `ss` output shows
  `127.0.0.1` / `::1` on both ends.
- **A firewall.** The listeners are open on the VM; nothing filters them.
- **Anything to grade.** No target, no check. Killing a `lab-*` service just
  removes that socket from the output; `sudo systemctl start` brings it back.

## When you're done

```sh
astrona destroy ss-socket-diagnostics-playground
```

(`astrona destroy` takes the environment name, not the config path.)
