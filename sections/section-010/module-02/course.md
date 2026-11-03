# Managing Linux Hostnames

Astronaut, every ship in the fleet needs a name. A **hostname** is the name that identifies a Linux machine. It lets people and tools talk about `prod-app-01` instead of `192.168.1.50`. A well-chosen name also carries information: `prod-app-01` reads as "the first application server in production".

On a machine that runs `systemd` (the service manager on almost every current Linux distribution), the picture is a little bigger than one name. `systemd` keeps **three** hostname values at once: static, transient and pretty. This module shows you all three, how to change each one on its own, and which ones survive a reboot.

One thing a hostname does *not* do: setting it does not make the machine reachable by that name. Something else has to map the name to an IP address, either DNS or the file `/etc/hosts`. Here the focus is the name itself.

## Learning objectives

After this module you can:

- Name the three hostname types `systemd` keeps (static, transient and pretty) and say what each one is for.
- Read `hostnamectl status`, find the static hostname, and explain when a separate `Transient hostname:` line appears.
- Set a persistent hostname with `sudo hostnamectl set-hostname --static` and check it in `/etc/hostname`.
- Set a transient (runtime-only) hostname and a pretty (human-readable) hostname without changing the technical name.
- Explain why setting a hostname does not make the machine reachable by that name, and name the mechanisms that do.
- Predict which hostname values survive a reboot and which do not.

## Before you start

Check that you have the knowledge this module expects, and know what is waiting in your playground.

### What you should already know

- **How to use a shell.** You can open a terminal and run commands with `sudo`.
- **What an IPv4 address looks like.** You have seen a dotted address such as `192.168.1.50`.

The module assumes a distribution that uses `systemd`, because every command here is `hostnamectl`. You need no knowledge of DNS or `/etc/hosts`.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine with `systemd`. Open a terminal on it with `astrona ssh linux-hostnames-playground`.

It starts with the three hostname types set to three different values, so `hostnamectl status` has something to show:

| Hostname type | Value at start |
| --- | --- |
| Static | `web-01`, stored in `/etc/hostname` |
| Transient | `dhcp-guest-42`, set at startup on purpose so it differs from the static one |
| Pretty | not set, left for you |

There is no DHCP server here, so the startup script `bootstrap/prepare.sh` sets the transient name itself. On a real host it would often come from DHCP. The tools `hostnamectl` and `hostname` come with the base system. Every command in this module is safe here. One step reboots the machine and drops your SSH session for about a minute.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Three Names For One Ship](./course-01-three-names-for-one-ship.md): static, transient and pretty hostnames, the naming rules, `hostnamectl`, and setting the static hostname.
2. [Pretty Names, Transient Names And Reboots](./course-02-pretty-transient-and-reboots.md): setting the pretty and transient hostnames, why a name is not an address, and which values survive a reboot.
3. [Wrap-Up: Mission Debrief](./course-03-wrap-up.md)

## Why this matters

The hostname is the first thing you see in a shell prompt, a log line or a monitoring screen. A machine with the wrong name, or a name that disappears at the next reboot, confuses every person and tool that reads it.

The exam asks you to set a hostname that lasts, and to know the difference between the name stored on disk and the name the running kernel uses. It also expects you to know that a name alone does not make a machine reachable.
