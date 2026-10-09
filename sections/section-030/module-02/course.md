# firewalld Zones and Services

Astronaut, writing every shield rule by hand works, but it is slow on a busy ship. **firewalld** gives you shield presets instead. It is a service that manages the Linux host firewall through a higher-level model than raw rules.

You do not write single filter rules with it. You tell it *which antenna (network interface) belongs to which trust level*, and *which services should be reachable there*. firewalld then writes the low-level rules for you. On current distributions those low-level rules are **nftables** rules, the same kernel shields you can program by hand with `nft`. Its command-line console is `firewall-cmd`.

firewalld is called **dynamic** because a change goes live without tearing down and rebuilding the whole ruleset: connections already in progress are left alone while the new rules slot in.

Two ideas carry most of firewalld:

- A **zone** is a named trust level, a shield preset such as `public`, `internal`, `trusted` or `drop`. It is bound to one or more interfaces or source addresses, and it carries its own list of what is allowed. An incoming packet is handled by the zone its **incoming interface** (or source address) is bound to.
- A **service** is a named bundle of ports and protocols: `ssh` is TCP (Transmission Control Protocol, a steady two-way conversation between programs) port 22, `http` is TCP port 80, `https` is TCP port 443. Allowing a service in a zone opens its ports there, without you having to remember the numbers.

## Learning objectives

After this module you can:

- Explain what firewalld adds on top of the kernel firewall, and what "dynamic" means when a change goes live.
- Name firewalld's two configuration directories and say which one you edit; name the two backends and which one is current.
- Describe the built-in zones and their targets, and state the order that decides which zone handles a packet.
- Read the default zone and the active zones with `firewall-cmd`, and list the services and ports a zone allows with `--list-all`.
- Open a port, a port range and a named service in a zone, both at runtime and permanently, and explain the `--permanent` and `--reload` split, including which commands change both.
- Write a rich rule that allows one source network to reach one service, with logging.
- Move an interface into a zone with `--change-interface`, bind a source address to a zone, and explain what makes each binding survive a reboot.
- Explain how firewalld relates to the nftables ruleset underneath it, and why hand-written `nft` rules clash with it.

## Before you start

Run a short pre-flight check before you touch the shield presets. Make sure you have the knowledge this module expects, and know what is waiting in your playground.

### What you should already know

- **The shell.** You can open a terminal and run commands with `sudo` (borrowing the captain's authority).
- **Ports and addresses.** You know what a TCP port and an IPv4 address are. Knowing a little nftables helps, because firewalld writes nftables rules, but it is not required. Zone, service and the runtime and permanent split are explained when they first appear.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. Open a shell on it with `astrona ssh firewalld-zones-playground`. Commands that change the firewall use `sudo`, and `sudo` needs no password.

| What | Details |
| --- | --- |
| firewalld | Running with its stock defaults: default zone `public`, the `ssh` service allowed, nothing custom added. `firewall-cmd --state` returns `running`. |
| Tools | `firewall-cmd`, plus `curl` and `python3` for test traffic |
| Management interface | The antenna that carries your SSH session. Leave its zone alone. |
| A second address | `192.168.90.10/24` on a local `dummy` interface, a practice antenna for moving interfaces between zones and binding source addresses |

Find the names of both interfaces with `ip -brief -4 addr show`.

Several steps need a program listening on a port. Start one with `python3 -m http.server 8080` in a second SSH (Secure Shell, the sealed communications channel between ships) session, or add `&` to run it in the background.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Architecture And The nftables Backend](./course-01-architecture-and-backends.md): the daemon, `firewall-cmd`, the two configuration directories, and the nftables table firewalld writes.
2. [Zones](./course-02-zones.md): a zone as a named policy, the built-in zones and their targets, and how a packet's zone is chosen.
3. [Services, Ports And Rich Rules](./course-03-services-ports-richrules.md): what a service contains, services against raw ports, forward ports and rich rules.
4. [Runtime, Permanent And Operations](./course-04-runtime-permanent-operations.md): the runtime and permanent split, the commands that bridge it, interface persistence and lock-outs.
5. [Wrap-Up: Mission Debrief](./course-05-wrap-up.md): what you learned, your mission, a self-check and clean-up.

## Why this matters

On many Linux ships, firewalld already owns the shields when you arrive. On the exam you open services and ports in the right zone and must make the change both live now and saved for after a reload. Mixing those two up is the most common firewalld mistake, and this module trains you to avoid it.
