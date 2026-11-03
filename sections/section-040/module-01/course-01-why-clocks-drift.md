# Why Clocks Drift

Astronaut, before you fix a ship's clock, see why it needs fixing. This part explains what goes wrong when time is off, which program keeps the time right on Ubuntu, and what a clock with no time beacon looks like.

## What goes wrong with bad time

Every computer has a clock that runs slightly fast or slightly slow. Left alone, a typical machine drifts by seconds per day. That is enough to break things that expect accurate time:

- Transport Layer Security (TLS), the lock on secure web connections, checks whether a certificate is valid yet, and whether it has expired.
- Kerberos, a login ticket system, rejects a clock difference of more than five minutes.
- Log timestamps from several servers no longer line up, so you cannot tell what happened first.
- Scheduled jobs run at the wrong moment.
- Any system spread over several machines that orders events by time gets the order wrong.

## NTP and chrony

Two names do the work in this module: the protocol, and the program that speaks it. This section introduces both, plus the one number that tells you how good a time source is.

### The time signal

The **Network Time Protocol (NTP)** keeps the clock correct. Think of it as the time signal ships use to keep their clocks in step. The client asks time servers what time it is, measures how long the signal took to travel there and back, and keeps nudging the local clock to match.

### The clockmaster

On most current Linux distributions, the program that does this is **chrony**. It has two pieces:

- `chronyd` is the background service that actually corrects the clock. It is the ship's clockmaster.
- `chronyc` (chrony *control*) is the console you use to talk to the clockmaster.

chrony is built to cope with laptops that sleep, virtual machines whose clocks jump, and network links that come and go. The older `ntpd` handled those cases poorly.

### Stratum

A key idea is **stratum**: how many relays the time passed through since the master clock.

- Stratum 0 is a reference clock itself, such as a Global Positioning System (GPS) receiver or an atomic clock.
- A server directly attached to one is stratum 1.
- A server that syncs to *that* server is stratum 2, and so on.

Your machine ends up one stratum below whichever source it locks onto.

## One clockmaster per ship

chrony is only one NTP program. Before you use it, know what else might be running and why only one may steer the clock.

- `systemd-timesyncd` ships enabled on some minimal installs. It is a lighter option that can only act as a client.
- `ntpd` and `ntpsec` are the older, full implementations.

**Only one may run at a time.** Two services that both steer the clock fight each other, like two pilots on one control stick. On virtual machines, the hypervisor also offers a paravirtualised clock (`kvm-clock`) that keeps the guest close to the host. NTP still runs on top of it, to correct what drift remains and to give a stratum you can trace.

## Reading `chronyc`

`chronyd` corrects the clock. `chronyc` is the tool you talk to it with, and its subcommands fall into two groups:

| Kind | Subcommands | Needs `sudo` |
|---|---|---|
| **Query** | `tracking`, `sources`, `sources -v`, `sourcestats` | no |
| **Control** | `add`, `delete`, `makestep`, `burst` | yes |

`tracking` is the one overall summary: which source is in charge, and how far off the clock is. `sources` is the table with one row per source. `add` and `delete` change only the running service; anything that must survive a restart goes in the configuration file.

## The starting point: a clock with nowhere to look

`chronyc tracking` prints what chrony currently believes about the clock. `chronyc sources` lists the time sources it is polling. On your playground client every source is cleared, so both have little to say. That "not synchronised" state is worth seeing before you fix it.

### See it in your playground

<!-- astrona:playground:renew -->

On `ntp-client`, ask the clockmaster for its summary and its list of sources:

```sh
chronyc tracking
chronyc sources -v
```

Expect a reference ID of all zeros and no sources listed:

```text
Reference ID    : 00000000 ()
Stratum         : 0
...
Leap status     : Not synchronised
```

```text
Number of sources = 0
```

`Leap status : Not synchronised` and `Stratum : 0` mean chrony has nothing to steer the clock by. The system time is just whatever the hardware clock says, drifting on its own.

## Common pitfalls

> [!WARNING]
> - **Two time services at once.** `systemd-timesyncd` and chrony both running will conflict. `timedatectl` shows which service is active; disable the one you are not using (`sudo systemctl disable --now systemd-timesyncd`).
> - **Forgetting the firewall.** NTP uses UDP port 123. A client needs outgoing traffic on port 123 allowed; a machine acting as a server also needs incoming traffic on port 123.
> - **Reading `Stratum : 0` as "best".** Here it means chrony has no source at all, not that the ship holds a reference clock.
