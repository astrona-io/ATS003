# NTP Server Mode and Stratums

Astronaut, a ship that keeps good time can share it. In this module your ship stops only listening to a time beacon and becomes one: it answers the Network Time Protocol (NTP) questions of other ships in its sector, so the whole fleet keeps the same time.

Organisations run their own NTP servers so that hundreds of internal machines sync against a couple of local servers, instead of each one reaching out to the public pool. Networks with limited or no internet access then still share one time source. A typical shape:

```text
public pool  ->  2-4 internal NTP servers  ->  every other host
```

## Learning objectives

After this module you can:

- Explain why an organisation runs internal NTP servers, and that chrony serves time from the same service that acts as a client.
- Grant client access with the `allow` directive (and `deny` for exceptions), in the configuration file and at runtime with `chronyc`.
- Explain what `local stratum` does and when an isolated network needs it.
- Describe how stratum numbers relate a server to its clients and to a reference clock.
- Monitor a running server with `chronyc serverstats` and `chronyc clients`.
- State the firewall rule an NTP server needs and why `allow` alone is not enough.

## Before you start

Every mission starts with a pre-flight check. Make sure you know the client side of chrony, and know what is waiting in your playground.

### What you should already know

- How to open a shell, use `sudo`, edit a text file, and read a dotted IPv4 address with a prefix such as `192.168.101.0/24`.
- The client side of chrony: a `server` line in `/etc/chrony/chrony.conf` names a time source, `iburst` makes the first sync fast, and every change to the file needs `sudo systemctl restart chrony`.
- How to read `chronyc sources` (`^*` marks the selected server, `Reach 377` means the last eight polls were answered) and `chronyc tracking` (`Leap status : Normal` means synchronised).

### What is in your playground

Your playground is two training ships flying in formation on an isolated segment, `192.168.101.0/24`:

| Machine | Address | State at start |
| --- | --- | --- |
| `ntp-server` | `192.168.101.10` | chrony running with `local stratum 10`, so it has a clock to serve, but **no `allow` line**, so it refuses every query. This is the machine you configure. |
| `ntp-client` | `192.168.101.20` | chrony already pointed at `192.168.101.10`. Its source sits in the `?` (refused) state until you open the server up. |

Run `astrona list` to see both machine names, then `astrona ssh <name>` to open a shell on one. Most commands run on **`ntp-server`**; the client is there to show whether the server is answering. `sudo` needs no password. Neither machine runs a firewall, so `allow` is the only access control in play.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [One Service, Two Jobs](./course-01-one-service-two-jobs.md): why internal time servers exist, stratum, and a server that answers no one.
2. [Open The Server With `allow`](./course-02-open-the-server-with-allow.md): grant access, confirm it from both sides, and change access at runtime.
3. [Local Stratum And Firewalls](./course-03-local-stratum-and-firewalls.md): serve time with no upstream, and open User Datagram Protocol (UDP) port 123, the NTP radio channel.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, and cleanup.

## Why this matters

An internal NTP server sits between the public pool (or a hardware clock) and the rest of the fleet. Secure connections, Kerberos logins and log correlation on every other machine depend on it. Turning a chrony client into a server is mostly one configuration line, and the exam expects you to write that line, open the firewall, and prove that a client really syncs through it.
