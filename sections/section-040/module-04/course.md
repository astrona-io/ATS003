# DNS Client Resolution

Astronaut, every ship carries a directory clerk who turns names into call signs. When an application asks for `db.lab.example`, it does not ask the galaxy-wide directory itself. It asks the clerk on board, and the clerk follows a fixed routine. This module shows how that clerk works on Ubuntu 24.04, who the clerk calls, and how you change the routine.

## Learning objectives

After this module you can:

- Explain the order in which a ship checks `/etc/hosts` and the directory, and where that order is written (`/etc/nsswitch.conf`).
- Explain why `getent hosts` and `dig` can give different answers.
- Describe the stub resolver `systemd-resolved` on `127.0.0.53` and read `/etc/resolv.conf`.
- Read the resolver state with `resolvectl status` and test names with `resolvectl query`.
- Set the DNS servers and search domains for the whole ship with a drop-in file, and for one interface with Netplan.
- Clear the resolver cache after a change.

## Before you start

A short pre-flight check: the knowledge this module expects, and what is waiting in your playground.

### What you should already know

- **Names and addresses.** DNS (Domain Name System) is the galaxy-wide directory of call signs. A record such as `A` is one line on a directory page.
- **The shell.** You can open a shell, edit a file as root and use `sudo`.

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine. Open a shell with `astrona ssh dns-resolver-playground`. The ship runs its own small DNS server, so you can practise without the internet:

| Item | What it is |
| --- | --- |
| interface `dns0` | a practice antenna with `10.55.0.53/24` |
| `named` (BIND) on `10.55.0.53` | a DNS server for the zone `lab.example` |
| `www.lab.example` | `203.0.113.10` |
| `db.lab.example` | `203.0.113.20` |
| `app.lab.example` | `203.0.113.30` |
| `systemd-resolved` | the clerk on board, at stock settings, not yet told about the server |

The management interface carries your own session. Never change it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Who Answers A Name](./course-01-who-answers-a-name.md): the order of the checks and why tools disagree.
2. [The Stub Resolver](./course-02-the-stub-resolver.md): `systemd-resolved`, `127.0.0.53` and `resolvectl`.
3. [Servers And Search Domains](./course-03-servers-and-search-domains.md): tell the clerk which directory to call and which suffix to add.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, a self-check and cleanup.

## Why this matters

"The network is down" is very often "the name does not resolve". The exam expects you to know which file or service decides, and to fix a resolver so that the change survives a restart.
