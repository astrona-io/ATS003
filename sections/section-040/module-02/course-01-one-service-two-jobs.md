# One Service, Two Jobs

Astronaut, the clockmaster on your ship already knows how to *listen* to a time beacon. In this part you learn that the same clockmaster can also *broadcast* the time to other ships, what number it advertises when it does, and why a fresh server still answers no one.

## Why run an internal time server

An internal NTP server lets many machines share one good clock. NTP is the Network Time Protocol, the time signal ships use to keep their clocks in step. Two facts make serving time simpler than it sounds.

### There is no separate server program

The same `chronyd` service that syncs your clock can also answer other machines' queries. A machine with good time is already able to serve it. `chronyd` is the clockmaster; `chronyc` is the console you use to talk to it.

### By default, it answers no one

`chronyd` drops every incoming client query until you permit a range of addresses with the `allow` directive. Turning a client into a server is mostly adding that one line.

### Run more than one

Run **more than one** internal server; three or four is common. Clients list all of them. chrony compares their answers, throws out any that disagree with the majority (the "falsetickers"), and keeps working if one server goes down. A single NTP server is a single point of failure for time across the whole network.

For timing below a microsecond (finance, telecoms), NTP gives way to the Precision Time Protocol (PTP, IEEE 1588) with hardware timestamps. That is a separate topic.

## Serving-side `chronyc`

The client side of `chronyc` queries the clock and adds sources. The serving side adds four more subcommands, in the same split between queries and controls:

| Kind | Subcommands | Purpose |
|---|---|---|
| **Query** | `serverstats`, `clients` | counters, and the list of hosts that have queried this server |
| **Control** | `allow <subnet>`, `deny <subnet>` | open or close access on the running service |

`allow` and `deny` exist both as `chronyc` subcommands (runtime only) and as `chrony.conf` directives (persistent). Same syntax, two lifetimes.

## Stratum

**Stratum** is how many relays the time passed through since the master clock. A server advertises it to every client, so you need to know what the number means before you serve time.

### The levels

- **Stratum 0** is a reference clock itself: a Global Positioning System (GPS) receiver, a radio clock, an atomic clock. It is not on the network.
- **Stratum 1** is a server directly attached to a stratum 0 device.
- **Stratum 2** is a server that syncs to a stratum 1 server. And so on, each hop adding one.
- **Stratum 16** means *not synchronised*. 15 is the highest usable value.

A server always advertises a stratum one higher than the source it is synced to, and its clients end up one higher again. If this server synced to a stratum 2 upstream, it would serve stratum 3, and its clients would be stratum 4.

### The playground server's own clock

The playground's server has **no upstream at all**. Left alone, it would report stratum 16 (not synchronised) and no client would trust it. A `local stratum 10` line in its configuration file prevents that. First, see the stratum it claims.

<!-- astrona:playground:renew -->

On `ntp-server`, ask the clockmaster for its summary:

```sh
chronyc tracking
```

Expect a local reference and stratum 10:

```text
Reference ID    : 7F7F0100 ()
Stratum         : 10
...
Leap status     : Normal
```

`Reference ID : 7F7F0100` with an empty name is chrony referring to *its own* clock: there is no real upstream. `Stratum : 10` is the number the `local` directive told it to claim. Clients that sync to it will be stratum 11.

## The default: a chrony host answers no one

The server is fully running and has a clock it could serve, and it still refuses every client. The `ntp-client` machine has pointed at it since boot, so its sources table shows the refusal.

### See the client being turned away

On `ntp-client`, list the sources:

```sh
chronyc sources -v
```

Expect the source present but unusable:

```text
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^? 192.168.101.10                0   6     0     -     +0ns[   +0ns] +/-    0ns
```

`^?` means chrony has a source configured, but has had no usable reply from it. `Reach 0` means none of its polls were answered. The network path is fine; the server is choosing not to respond.

## Common pitfalls

> [!WARNING]
> - **Forgetting `allow`.** A freshly configured chrony server answers nobody until an `allow` line names their range. This is the most common "my NTP server is not working".
> - **One server only.** No redundancy, no falseticker detection. Run several and list them all on every client.
> - **Reading stratum as quality.** Stratum counts hops from a reference clock. A low number only says the source is close to one; `local stratum` lets a server claim any number.
