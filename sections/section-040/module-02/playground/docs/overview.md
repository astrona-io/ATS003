# Overview: PLAYGROUND — NTP Server Mode and Stratums (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs its OS
prep, and then waits. There is no task, no `astrona submit`, and no pass/fail.
Explore, break things, `astrona destroy`, start over.

## What's in the box

Two qemu VMs on one isolated segment, `192.168.101.0/24`:

| VM | Address | State at boot |
| --- | --- | --- |
| `ntp-server` | `192.168.101.10` | chrony running, `local stratum 10`, **no `allow` line** — refuses every client query. |
| `ntp-client` | `192.168.101.20` | chrony pointed at `192.168.101.10 iburst`. Its source is stuck in the `?` (unreachable/refused) state. |

Run `astrona list` for the exact VM names, then `astrona ssh <name>`. Most of
the work is on **`ntp-server`**; `ntp-client` is there to prove the server is or
is not answering. `sudo` needs no password. Neither VM runs a firewall, so the
`allow` directive is the only thing gating access.

## Things to try

On **`ntp-server`** (`/etc/chrony/chrony.conf`, then
`sudo systemctl restart chrony`):

- **See it refusing clients.** `sudo chronyc serverstats` — "NTP packets
  received" barely moves; `sudo chronyc clients` is empty.
- **Open it up.** Uncomment / add `allow 192.168.101.0/24`, restart, then
  re-check `chronyc clients` and `chronyc serverstats`.
- **Narrow it.** Try `allow 192.168.101.20` (one host) or a `deny` line for a
  sub-range, restart, and watch which clients get answered.
- **Read its own clock.** `chronyc tracking` on the server shows
  `Reference ID : 7F7F0100 ()` and `Stratum : 10` — the `local` directive at
  work. Change `local stratum 10` to `local stratum 8` and see the client's
  stratum follow.
- **`chronyc -N authhash`, `chronyc ntpdata`** and other read-only queries.

On **`ntp-client`**:

- **Watch the flip.** `watch -n1 chronyc sources -v` while you add `allow` on
  the server — the state column goes `?` -> `*` within a poll or two.
- **`chronyc tracking`** — after the flip, `Reference ID` names
  `192.168.101.10` and `Stratum` is one below the server's.

## What this sandbox does not set up

- **A real upstream / internet NTP.** The server's time comes from `local
  stratum`, not a true reference. Do not copy `local stratum` onto a
  production server that has genuine upstream sources.
- **A firewall.** UDP 123 is wide open on the segment; `allow`/`deny` is the
  only access control here. On a real server you also need inbound 123 through
  nftables / firewalld / ufw.
- **NTS (authenticated NTP).** Out of scope.
- **Anything to grade.** No target config, no check.

## When you're done

```sh
astrona destroy ntp-server-playground
```

(`astrona destroy` takes the environment name, not the config path.)
