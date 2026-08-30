# NTP Client Time Synchronization

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-040/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-040/module-01/playground
> astrona destroy ntp-chrony-playground
> ```

Every computer has a clock that runs slightly fast or slightly slow. Left alone, a typical machine drifts by seconds per day — enough to break things that assume accurate time: TLS certificate validity checks, Kerberos authentication (which rejects a skew over five minutes), correlating log timestamps across servers, scheduled jobs, and any distributed system that orders events by time.

**NTP**, the Network Time Protocol, keeps the clock correct by asking time servers what time it is, measuring the network round-trip, and continuously nudging the local clock to match. On most current Linux distributions the program that does this is **chrony**: a background daemon, `chronyd`, plus a control and query tool, `chronyc`. chrony is built to cope with laptops that sleep, VMs whose clocks jump, and links that come and go — cases the older `ntpd` handled poorly.

A key idea is **stratum** — how many hops a source is from a reference clock. Stratum 0 is a reference clock itself (GPS, an atomic clock); a server directly attached to one is stratum 1; a server syncing to *that* is stratum 2, and so on. Your machine ends up one stratum below whichever source it locks onto.

## Learning objectives

After this module you can:

- Explain why system clocks drift and what breaks when the time is wrong.
- Configure a time source in `/etc/chrony/chrony.conf` with `server` or `pool`, and explain what `iburst`, `minpoll`, and `maxpoll` do.
- Add and remove a source at runtime with `chronyc`, and explain why that is not persistent.
- Read `chronyc sources -v` and `chronyc tracking` — the source state flags, reachability register, stratum, offset, and leap status.
- Explain the difference between slewing and stepping the clock, and what `makestep` controls.
- Confirm system-wide synchronisation state with `timedatectl`.

## Before you start

This module assumes you can open a shell, run commands with `sudo`, edit a text file, and have seen a dotted IPv4 address. NTP, stratum, offset, poll interval, and slew-versus-step are all defined as they come up. The firewall modules are useful background — NTP is UDP port 123 — but are not required.

The playground is **two VMs** on an isolated segment, `192.168.100.0/24`:

- **`ntp-server`** (`192.168.100.10`) — chrony already set up as a local time source at stratum 8. Nothing to do here; it just needs to be reachable.
- **`ntp-client`** (`192.168.100.20`) — chrony installed and running, but every default source commented out, so it starts with **no sources**.

Every checkpoint runs on **`ntp-client`**. Open a shell on it with `astrona ssh astro-ntp-client` (confirm the exact names with `astrona list` if needed). `sudo` needs no password. There is no internet NTP here — `ntp-server` is the only reachable source, which is what makes the sync loop fully visible.

## Where this fits

Time synchronisation is a dependency of things that rarely mention it until they break: a TLS handshake fails because the certificate is "not yet valid", a Kerberos ticket is refused for clock skew, log lines from two hosts cannot be interleaved, a database's multi-node ordering goes wrong. Getting NTP right on every host is baseline infrastructure work.

chrony is only one NTP implementation. `systemd-timesyncd` ships enabled on some minimal installs and is a lighter client-only option; `ntpd` and `ntpsec` are the older full implementations. **Only one may run at a time** — two daemons both steering the clock fight each other. On virtual machines the hypervisor also offers a paravirtualised clock (`kvm-clock`) that keeps the guest close to the host, but NTP still runs to correct residual drift and to give a traceable stratum.

## Reading `chronyc`

`chronyd` is the daemon that actually disciplines the clock. `chronyc` — chrony *control* — is the tool you talk to it with, and its subcommands split cleanly:

| Kind | Subcommands | Needs `sudo` |
|---|---|---|
| **Query** | `tracking`, `sources`, `sources -v`, `sourcestats` | no |
| **Control** | `add`, `delete`, `makestep`, `burst` | yes |

`tracking` is the one overall summary — which source is in charge, how far off the clock is. `sources` is the per-source table. `add` / `delete` change the running daemon only; anything that must survive a restart goes in the config file.

## The starting point: a clock with nowhere to look

`chronyc tracking` prints what chrony currently believes about the clock. `chronyc sources` lists the time sources it is polling. With the client's sources cleared, both have little to say — and that "not synchronised" state is worth seeing before you fix it.

> [!TIP]
> **Try it — an unsynchronised client**
>
> ```sh
> chronyc tracking
> chronyc sources -v
> ```
>
> Expect a reference ID of all zeros and no sources listed:
>
> ```text
> Reference ID    : 00000000 ()
> Stratum         : 0
> ...
> Leap status     : Not synchronised
> ```
>
> ```text
> Number of sources = 0
> ```
>
> `Leap status : Not synchronised` and `Stratum : 0` mean chrony has nothing to steer the clock by. The system time is just whatever the hardware clock says, drifting on its own.

## Configuring a time source

A source is one line in chrony's config file — `/etc/chrony/chrony.conf` on Debian and Ubuntu, `/etc/chrony.conf` on RHEL-family systems. Two directives add sources:

- `server <address> [options]` — one specific server.
- `pool <name> [options]` — a DNS name that resolves to *several* servers; chrony keeps a handful and drops any that misbehave. Public NTP is normally used this way (`pool 2.pool.ntp.org iburst`).

The options that matter early:

- `iburst` — on startup, send a quick burst of a few packets a couple of seconds apart instead of one every ~64 seconds. First sync drops from minutes to seconds. Use it on every source.
- `minpoll N` / `maxpoll N` — bounds on how often chrony polls this source, as a power of two seconds (`6` = 64 s, the default lower bound; `10` = 1024 s). chrony moves the interval within that range on its own.

You can also add a source **without editing the file**, straight into the running daemon, with `chronyc add`. That change lasts only until chrony restarts — useful for testing a source before committing it to the config.

> [!TIP]
> **Try it — add the local server and watch the client lock on**
>
> ```sh
> sudo chronyc add server 192.168.100.10 iburst
> chronyc sources -v
> ```
>
> Run `chronyc sources` again a few seconds later (or `watch -n1 chronyc sources`). Within a few seconds `iburst` gets chrony enough samples to select the source:
>
> ```text
> MS Name/IP address         Stratum Poll Reach LastRx Last sample
> ===============================================================================
> ^* 192.168.100.10                8   6    17     3   +12us[  +38us] +/-  412us
> ```
>
> The `*` in the second column means **this is the source chrony is now synchronised to**. `^` means it is a server (not a peer or a local clock). The client is now stratum 9 — one below the server's 8.

## Reading `chronyc sources -v`

The `-v` flag prints a legend above the table. The columns, left to right:

- **M** — mode: `^` server, `=` peer, `#` local reference clock.
- **S** — state: `*` selected and synced, `+` a good source being combined, `-` a usable source not currently combined, `?` unreachable, `x` a "falseticker" (its time disagrees with the others), `~` too variable to trust.
- **Stratum** — the source's stratum.
- **Poll** — current poll interval, as a power of two seconds (`6` = 64 s).
- **Reach** — an octal view of the last eight polls. Each successful poll shifts a `1` in from the right, so `377` (octal for `11111111`) means the last eight all got a reply. A lower number early on just means fewer samples so far, not a problem.
- **LastRx** — seconds since the last reply.
- **Last sample** — the measured offset to this source, with error bounds.

> [!TIP]
> **Try it — watch the reachability register fill up**
>
> A minute or so after adding the source:
>
> ```sh
> chronyc sources -v
> ```
>
> Expect `Reach` to have climbed toward `377`:
>
> ```text
> ^* 192.168.100.10                8   6   377    41   +3us[  +9us] +/-  350us
> ```
>
> `Reach 377` means all eight of the most recent polls were answered — a source that is responding reliably. The `Last sample` offset (here microseconds) is how far the client's idea of time differs from the server's.

## Reading `chronyc tracking`

Where `sources` is per-source, `tracking` is the **overall** picture: which source is in charge and how well the clock is disciplined.

> [!TIP]
> **Try it — the synchronised tracking state**
>
> ```sh
> chronyc tracking
> ```
>
> Expect the reference to name the server now, and the leap status to be normal:
>
> ```text
> Reference ID    : C0A8640A (192.168.100.10)
> Stratum         : 9
> Ref time (UTC)  : Fri Aug 29 12:00:00 2026
> System time     : 0.000004521 seconds slow of NTP time
> Last offset     : +0.000001893 seconds
> RMS offset      : 0.000030124 seconds
> Frequency       : 12.301 ppm slow
> Skew            : 0.512 ppm
> Leap status     : Normal
> ```
>
> `Reference ID` is the server's address in hex; `Stratum 9` is one below it; `System time ... slow of NTP time` is the current offset; `Frequency` is how far off the hardware clock's rate is, which chrony now corrects continuously. `Leap status : Normal` means synchronised. Values vary every run.

## Making the source persistent

`chronyc add` lives only in the running daemon. To keep a source across restarts and reboots, it has to be in the config file.

> [!TIP]
> **Try it — the runtime source does not survive a restart; a config line does**
>
> Restart chrony and confirm the `chronyc add` source is gone:
>
> ```sh
> sudo systemctl restart chrony
> chronyc sources
> ```
>
> Expect `Number of sources = 0` again. Now add it to the file and restart once more:
>
> ```sh
> echo 'server 192.168.100.10 iburst' | sudo tee -a /etc/chrony/chrony.conf
> sudo systemctl restart chrony
> chronyc sources -v
> ```
>
> This time the source is back after the restart. Editing the config file without restarting (or `sudo systemctl reload chrony`) has no effect — chrony reads the file only at start.

## Slewing versus stepping the clock

chrony corrects the clock two ways:

- **Slewing** — speeding the clock up or slowing it down slightly until it catches up. The clock never jumps and never goes backwards. Used for small offsets.
- **Stepping** — setting the clock to the correct time in one jump. Fast, but time can appear to move backwards, which some software handles badly. Used only when the offset is too large to slew in reasonable time.

The `makestep <threshold> <limit>` directive controls automatic stepping: if the offset exceeds `<threshold>` seconds, chrony is allowed to step — but only for the first `<limit>` clock updates after it starts (so a machine can jump to the right time at boot, then only ever slew afterwards). Ubuntu's default is `makestep 1 3`. `chronyc makestep` forces a step by hand at any time.

> [!TIP]
> **Try it — knock the clock off and watch chrony pull it back**
>
> With the client synced, introduce a small error and watch it get slewed out — gradually, no jump:
>
> ```sh
> sudo date -s '+2 seconds'
> chronyc tracking | grep -E 'System time|Last offset'
> ```
>
> Expect `System time` to jump to about 2 seconds off, then shrink over the next minute or two as chrony slews:
>
> ```text
> System time     : 1.998xxx seconds fast of NTP time
> Last offset     : +1.998xxx seconds
> ```
>
> Re-run the `chronyc tracking` line every 20 seconds and the offset falls steadily rather than snapping to zero. To finish the correction instantly instead:
>
> ```sh
> sudo chronyc makestep
> chronyc tracking | grep 'System time'
> ```
>
> `makestep` jumps the clock the rest of the way in one move — the stepping behaviour, on demand.

## The system view: `timedatectl`

chrony is one time daemon among several (`systemd-timesyncd`, `ntpd`, `ntpsec`). `timedatectl` reports the system's synchronisation state without caring which one is running.

> [!TIP]
> **Try it — confirm the system considers itself synced**
>
> ```sh
> timedatectl
> ```
>
> Expect:
>
> ```text
>                Local time: Fri 2026-08-29 12:05:00 UTC
>            Universal time: Fri 2026-08-29 12:05:00 UTC
>                 RTC time: Fri 2026-08-29 12:05:00
>                Time zone: UTC (UTC, +0000)
> System clock synchronized: yes
>               NTP service: active
> ```
>
> `NTP service: active` means a time daemon (chrony, here) is running and `timedatectl` is willing to let it manage the clock; `System clock synchronized: yes` appears once that daemon reports a lock. Before you added a source, this line read `no`.

> [!WARNING]
> **Common pitfalls**
>
> - **Two time daemons at once.** `systemd-timesyncd` and chrony both running will conflict. `timedatectl` shows which service is active; disable the one you are not using (`sudo systemctl disable --now systemd-timesyncd`).
> - **`chronyc add` treated as permanent.** A runtime-added source is gone on the next restart. Put it in `chrony.conf` to keep it.
> - **Editing `chrony.conf` without restarting.** chrony reads the file only at start — no restart, no change.
> - **Expecting instant sync without `iburst`.** Without it, the first usable update can be over a minute away. Add `iburst` to every `server` and `pool` line.
> - **Misreading `Reach`.** It is octal and it fills up over the first eight polls. A value below `377` shortly after adding a source is normal, not a fault.
> - **Assuming a large offset gets stepped.** `makestep` only steps automatically for the first few updates after chrony starts (its `<limit>`). A big jump introduced later is slewed slowly unless you run `chronyc makestep`.
> - **Forgetting the firewall.** NTP is UDP 123. A client needs outbound 123 allowed; a machine acting as a server needs inbound 123.
