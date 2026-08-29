# Overview: PLAYGROUND — NTP Client Time Synchronization (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs its OS
prep, and then waits. There is no task, no `astrona submit`, and no pass/fail.
Explore, break things, `astrona destroy`, start over.

## What's in the box

Two qemu VMs on one isolated segment, `192.168.100.0/24`:

| VM | Address | Role |
| --- | --- | --- |
| `ntp-server` | `192.168.100.10` | chrony set up as a local NTP server (`local stratum 8`, `allow 192.168.100.0/24`). Serving on boot. |
| `ntp-client` | `192.168.100.20` | chrony installed and running, **all default sources commented out** — `chronyc sources` starts empty. |

Run `astrona list` to see both VM names, then `astrona ssh <name>` to shell into
one. Almost everything below is done on **`ntp-client`**; the server is just
there to be a reachable source. `sudo` needs no password.

There is no outbound internet NTP here — the server VM is the only source the
client can reach. That is deliberate: it makes the sync loop fully visible.

## Things to try (on `ntp-client`)

- **See the empty starting state.** `chronyc sources -v`, `chronyc tracking`.
  With no sources, `Reference ID` is `00000000` and `Leap status` is
  `Not synchronised`.
- **Add a source at runtime.** `sudo chronyc add server 192.168.100.10 iburst`,
  then `watch -n1 chronyc sources`. Watch the `*` appear next to the source and
  the offset column shrink.
- **Add it persistently.** Put `server 192.168.100.10 iburst` in
  `/etc/chrony/chrony.conf`, then `sudo systemctl restart chrony`. Confirm it
  survives a restart where the runtime `chronyc add` does not.
- **Read `chronyc tracking`.** After sync, `Reference ID` names the server,
  `Stratum` is one above the server's, and `System time` shows a small offset.
- **`chronyc sourcestats`** — the rate and spread estimates chrony builds per
  source over time.
- **`chronyc ntpdata 192.168.100.10`** — the raw last-exchange detail for that
  source.
- **Step vs slew.** `chronyc tracking` shows tiny corrections being *slewed*
  (speeding/slowing the clock). Force a large offset with
  `sudo date -s '+45 seconds'`, then watch whether chrony *steps* it back
  (allowed by `makestep`) or slews it, and how `System time` reacts.
- **`timedatectl`** — `NTP service: active` and `System clock synchronized: yes`
  once chrony has locked on.
- **Break it.** Stop chrony on `ntp-server` (`sudo systemctl stop chrony`
  there), then watch the client's source go unreachable in `chronyc sources`
  and `Leap status` drift back to `Not synchronised`.

## What this sandbox does not set up

- **Public NTP pools.** `pool` / `server ntp.ubuntu.com` lines will not resolve
  or reach anything. Use `192.168.100.10`.
- **NTS / authenticated NTP, or a GPS/PPS reference clock.** Out of scope here.
- **Anything to grade.** There is no target config and no check.

## When you're done

```sh
astrona destroy ntp-chrony-playground
```

(`astrona destroy` takes the environment name, not the config path.)
