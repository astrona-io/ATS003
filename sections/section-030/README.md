# Section 030: Network Security & Packet Filtering (Firewalls)

Astronaut, every ship needs shields. In this section you learn to program the Linux host firewall: the kernel's shield generator, netfilter, and the two consoles that control it. First you write the rules by hand with nftables, then you manage the same protection through firewalld zones and services.

## What you will be able to do

After this section you can:

- Build nftables tables, base chains and rules from an empty ruleset, and put each chain on the right hook.
- Drop a port, allow a port from one source only, block outgoing traffic to one host, and redirect one port to another.
- Keep a ruleset after a reboot with `/etc/nftables.conf` and `nftables.service`.
- Read and change firewalld zones, open services and ports, and write rich rules.
- Make every firewalld change both live now and saved for after a reload.

## The modules

Each module has a short landing page and a few parts. Read the landing page first, then the parts in order. Each module has its own playground and a graded mission.

1. [Packet Filtering with nftables](./module-01/course.md): the packet path, tables, chains, rules, rule order, port redirects, connection tracking, sets and maps, and persistence.
2. [firewalld Zones and Services](./module-02/course.md): the firewalld daemon, zones, services and rich rules, and the runtime and permanent split.

## Check your knowledge

When you have finished both modules, take the [Section 030 knowledge check](./quiz.md): short scenario questions on nftables and firewalld.

## The capstone

The section ends with one graded capstone mission with no step-by-step help: build a complete nftables policy on an empty ruleset, with a dropped port, a port redirect, a source-limited port and an outgoing block. Its task is in the [capstone question](./capstone/labs/lab-01/question.md).
