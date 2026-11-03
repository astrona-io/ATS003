# Local Hostname Resolution

Astronaut, a ship's name is no use on the radio until someone can look up its call sign. A hostname gives a machine a human-readable identity. **Name resolution** turns that name into an IP address an application can connect to. For example, it can turn `prod-app-01` into a loopback address such as `127.0.1.1`, or into an interface address such as `192.168.1.50`.

Linux can get that mapping from several sources: the local `/etc/hosts` file, a DNS server, multicast DNS, a service such as `systemd-resolved`, and others. When a program needs the address for a name, it does not go straight to DNS. It asks a switchboard, the **Name Service Switch (NSS)**, which checks a list of sources in a set order and returns the first answer. `/etc/hosts` is usually first on that list.

This module is about that local source, the ship's own pocket address book, and the switchboard in front of it.

## Learning objectives

After this module you can:

- Read an `/etc/hosts` line and find the IP address, the canonical hostname and any aliases.
- Explain why the NSS switchboard, not DNS directly, decides where a name lookup goes, and read the `hosts:` line in `/etc/nsswitch.conf` to see the order.
- Add or remove an `/etc/hosts` entry with `sudo` and confirm with `getent hosts` that it resolves at once.
- Explain why `getent` is a cleaner test of name resolution than `ping`.
- Choose between a loopback address such as `127.0.1.1` and an interface address for a hostname entry, based on how the name is used.
- Explain why an `/etc/hosts` entry resolves only on the machine that holds it, and when DNS is the right tool instead.

## Before you start

Check that you have the knowledge this module expects, and know what is waiting in your playground.

### What you should already know

- **How to use a shell.** You can open a terminal, run commands with `sudo` and edit a text file.
- **What an IPv4 address looks like.** You have seen a dotted address such as `192.168.1.50`.
- **What a static hostname is.** A machine has a lasting name, stored in `/etc/hostname` and set with `hostnamectl`.

DNS, NSS, the canonical hostname and loopback are all explained when they come up.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. Open a terminal on it with `astrona ssh hostname-resolution-playground`.

It starts with a prepared `/etc/hosts`:

| Line | What it does |
| --- | --- |
| `127.0.0.1 localhost` and `::1 localhost ...` | The standard entries |
| `127.0.1.1 prod-app-01 app-server` | Maps the static hostname `prod-app-01` (alias `app-server`) to the loopback address |
| `192.168.50.10 db-primary db` | Maps `db-primary` (alias `db`) to an address where nothing is listening, so you can watch a name resolve and still fail to connect |

`/etc/nsswitch.conf` is whatever the image ships, typically `hosts: files ... dns`. The playground network has no DNS server, so `files` is the only source that ever answers. The tools `getent`, `hostnamectl`, `grep` and `ping` are installed. Editing `/etc/hosts` here is safe and easy to undo.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [The Pocket Address Book](./course-01-the-pocket-address-book.md): the `/etc/hosts` format, `getent`, and the lookup order in `/etc/nsswitch.conf`.
2. [Write An Entry And Test It](./course-02-write-an-entry-and-test-it.md): choosing the address for an entry, adding one, why resolution is not reachability, and when to use DNS instead.
3. [Wrap-Up: Mission Debrief](./course-03-wrap-up.md)

## Why this matters

Many problems that look like "the network is down" are really "the name does not resolve", or "it resolves to the wrong address". Knowing where Linux looks first, and how to test resolution on its own, lets you tell those cases apart in seconds.

The exam asks you to add entries to `/etc/hosts`, prove that they resolve in both directions, and know when a local entry is the wrong tool.
