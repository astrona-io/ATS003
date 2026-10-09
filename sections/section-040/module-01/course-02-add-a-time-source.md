# Add A Time Source

Astronaut, your client's clockmaster has no time beacon to listen to. In this part you give it one, watch it lock on, and learn to read the two tables that tell you whether the clock is really in step.

## Configuring a time source

A time source is one line in chrony's configuration file. On Debian and Ubuntu that file is `/etc/chrony/chrony.conf`; on Red Hat family systems it is `/etc/chrony.conf`. This section shows the two directives that add a source and the options you will use most.

### `server` and `pool`

Two directives add sources:

- `server <address> [options]` names one specific server.
- `pool <name> [options]` names a DNS name that points to *several* servers. chrony keeps a handful of them and drops any that misbehave. Public NTP is normally used this way (`pool 2.pool.ntp.org iburst`).

DNS, the Domain Name System, is the galaxy-wide directory of call signs: it turns a name into addresses.

### The options that matter early

- `iburst`: on start-up, send a quick burst of a few packets a couple of seconds apart, instead of one about every 64 seconds. The first sync drops from minutes to seconds. Use it on every source.
- `minpoll N` and `maxpoll N`: the limits on how often chrony polls this source, as a power of two seconds. `6` means 64 seconds (the default lower limit) and `10` means 1024 seconds. chrony moves the interval within that range on its own.

### Adding a source at runtime

You can also add a source **without editing the file**, straight into the running service, with `chronyc add`. That change lasts only until chrony restarts. It is useful for testing a source before you write it into the configuration file.

## Watch the client lock on

The quickest way to see a source work is to add it at runtime and watch the sources table. Your playground's `ntp-server` is waiting at `192.168.100.10`.

### Add the local server

<!-- astrona:playground:renew -->

On `ntp-client`, add the server and look at the sources:

```sh
sudo chronyc add server 192.168.100.10 iburst
chronyc sources -v
```

Run `chronyc sources` again a few seconds later, or use `watch -n1 chronyc sources`. Within a few seconds, `iburst` gives chrony enough samples to select the source:

```text
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* 192.168.100.10                8   6    17     3   +12us[  +38us] +/-  412us
```

The `*` in the second column means **this is the source chrony is now synchronised to**. The `^` means it is a server (not a peer or a local clock). The client is now stratum 9, one below the server's 8.

## Reading `chronyc sources -v`

The sources table packs a lot into a few columns. The `-v` flag prints a legend above it. This section walks through each column, then shows how one of them changes over the first minute.

### The columns, left to right

- **M** is the mode: `^` server, `=` peer, `#` local reference clock.
- **S** is the state: `*` selected and synced, `+` a good source being combined, `-` a usable source not currently combined, `?` unreachable, `x` a "falseticker" (its time disagrees with the others), `~` too variable to trust.
- **Stratum** is the source's stratum.
- **Poll** is the current poll interval, as a power of two seconds (`6` = 64 seconds).
- **Reach** is an octal view of the last eight polls. Each answered poll shifts a `1` in from the right, so `377` (octal for `11111111`) means the last eight all got a reply. A lower number early on just means fewer samples so far, not a problem.
- **LastRx** is the number of seconds since the last reply.
- **Last sample** is the measured offset to this source, with error bounds.

### Watch the reachability register fill up

A minute or so after you added the source, look again:

```sh
chronyc sources -v
```

Expect `Reach` to have climbed toward `377`:

```text
^* 192.168.100.10                8   6   377    41   +3us[  +9us] +/-  350us
```

`Reach 377` means all eight of the most recent polls were answered: the beacon is answering reliably. The `Last sample` offset (here in microseconds) is how far the client's idea of time differs from the server's.

## Reading `chronyc tracking`

Where `sources` shows each source, `tracking` gives the **overall** picture: which source is in charge, and how well the clock is being corrected.

### The synchronised tracking state

Ask for the summary again:

```sh
chronyc tracking
```

Expect the reference to name the server now, and the leap status to be normal:

```text
Reference ID    : C0A8640A (192.168.100.10)
Stratum         : 9
Ref time (UTC)  : Fri Aug 29 12:00:00 2026
System time     : 0.000004521 seconds slow of NTP time
Last offset     : +0.000001893 seconds
RMS offset      : 0.000030124 seconds
Frequency       : 12.301 ppm slow
Skew            : 0.512 ppm
Leap status     : Normal
```

Read it line by line:

- `Reference ID` is the server's address written in hexadecimal.
- `Stratum 9` is one below the server.
- `System time ... slow of NTP time` is the current offset.
- `Frequency` is how far off the hardware clock's rate is. chrony now corrects that rate all the time.
- `Leap status : Normal` means synchronised.

Your values will be different every run.

## Common pitfalls

> [!WARNING]
> - **Expecting instant sync without `iburst`.** Without it, the first usable update can be over a minute away. Add `iburst` to every `server` and `pool` line.
> - **Misreading `Reach`.** It is octal, and it fills up over the first eight polls. A value below `377` shortly after adding a source is normal, not a fault.
> - **Reading `minpoll` and `maxpoll` as seconds.** They are powers of two: `4` means 16 seconds, `10` means 1024 seconds.
> - **Treating `chronyc add` as permanent.** A source added at runtime is gone on the next restart.
