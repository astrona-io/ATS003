# NTP Client Time Synchronization

Astronaut, every spaceship carries a clock, and no clock is perfect. Left alone, a ship's clock runs a little fast or a little slow, and after a few days it is seconds away from the rest of the fleet. Many things on board quietly depend on the right time, so a drifting clock breaks them without warning.

This module teaches you to keep one ship's clock in step with a time beacon. You set up **chrony**, the ship's clockmaster, as an NTP client: it listens to the Network Time Protocol (NTP), the time signal ships use to keep their clocks in step, and nudges the local clock until it matches.

## Learning objectives

After this module you can:

- Explain why system clocks drift and what breaks when the time is wrong.
- Configure a time source in `/etc/chrony/chrony.conf` with `server` or `pool`, and explain what `iburst`, `minpoll`, and `maxpoll` do.
- Add and remove a source at runtime with `chronyc`, and explain why that is not persistent.
- Read `chronyc sources -v` and `chronyc tracking`: the source state flags, reachability register, stratum, offset, and leap status.
- Explain the difference between slewing and stepping the clock, and what `makestep` controls.
- Confirm system-wide synchronisation state with `timedatectl`.

## Before you start

Every mission starts with a pre-flight check. Make sure you have the basic skills this module expects, and know what is waiting in your playground.

### What you should already know

- How to open a shell, run commands with `sudo`, and edit a text file.
- What a dotted IPv4 address such as `192.168.100.10` looks like.

NTP, stratum, offset, poll interval, and slewing versus stepping are all explained in the parts as they come up. Firewalls are useful background, because NTP uses User Datagram Protocol (UDP) port 123, but you do not need them here.

### What is in your playground

Your playground is two training ships flying in formation on an isolated segment, `192.168.100.0/24`:

| Machine | Address | Role |
| --- | --- | --- |
| `ntp-server` | `192.168.100.10` | chrony already set up as a local time source at stratum 8. Nothing to do here; it only needs to be reachable. |
| `ntp-client` | `192.168.100.20` | chrony installed and running, but every default source is commented out, so it starts with **no sources**. |

Every hands-on step runs on **`ntp-client`**. Run `astrona list` to see both machine names, then `astrona ssh <name>` to open a shell on one. `sudo` needs no password. There is no internet NTP here: `ntp-server` is the only time beacon the client can reach, and that makes the whole sync loop easy to watch.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Why Clocks Drift](./course-01-why-clocks-drift.md): what goes wrong with bad time, what chrony is, and a client with no sources.
2. [Add A Time Source](./course-02-add-a-time-source.md): `server` and `pool` lines, `chronyc add`, and how to read `sources` and `tracking`.
3. [Write The Source Into The Configuration File](./course-03-write-the-source-into-the-configuration-file.md): make a source survive a restart.
4. [Slew, Step And The System View](./course-04-slew-step-and-the-system-view.md): how chrony corrects the clock, and `timedatectl`.
5. [Wrap-Up: Mission Debrief](./course-05-wrap-up.md): what you learned, your mission, and cleanup.

## Why this matters

Time synchronisation is something other services depend on without saying so, until they break. A secure web connection fails because a certificate is "not yet valid". A Kerberos login ticket is refused because the clocks are too far apart. Log lines from two machines cannot be put in order. Getting NTP right on every machine is basic infrastructure work, and the exam expects you to do it quickly from a terminal.
