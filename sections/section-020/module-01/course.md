# Link Aggregation with Linux Bonding

Astronaut, a ship with one antenna has one weak spot: if that antenna fails, the ship goes silent. Linux **bonding** fixes that. It teams two or more network interfaces, the antennas on your ship's communications array, so the rest of the system sees them as one. The team is normally called `bond0`.

`bond0` is a *logical* interface. It is software in the kernel, the ship's core, on top of real network cards. It is not a port you can plug a cable into. Applications use `bond0` and never touch the member cards directly. Depending on the **bonding mode**, a bond can give you a spare link that takes over on failure, or more links that share the traffic.

## Learning objectives

After this module you can:

- Explain what a Linux bond is, why an IP address belongs on `bond0` rather than on its members, and what "member interface" means.
- Build a temporary active-backup bond with `ip link` and read its state from `/proc/net/bonding/bond0`.
- Compare the common bonding modes, active-backup (1), balance-tlb (5) and 802.3ad (4), by purpose, by what they need from the switch, and by whether more than one link carries traffic at once.
- Configure link monitoring with `miimon` and state what it detects and what it does not.
- Trigger a failover by taking the active member down, and find the new `Currently Active Slave`.
- Explain why a bond made with `ip` is lost on reboot, and name the systems that make one persistent.

## Before you start

Every mission starts with a pre-flight check. Make sure you have the basics this module expects, and know what is waiting in your playground.

### What you should already know

- **A shell and `sudo`.** You can open a terminal and run a command with `sudo`, which borrows the captain's authority.
- **Interface names and addresses.** You have seen interface names like `enp0s2` and an IPv4 address with a prefix, such as `192.168.50.50/24`. Everything else (MAC address, Layer 2, switch, LACP, hash) is explained when it first comes up.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. Open a terminal on it with `astrona ssh linux-bonding-playground`.

It has three usable network interfaces:

- **The management interface.** It carries your SSH (Secure Shell) session, your link to mission control, and it holds an address. Leave it alone.
- **Two spare member interfaces.** They have no address and no configuration. One sits on the `192.168.50.0/24` segment, the other on `192.168.51.0/24`. These are the antennas you team up in every hands-on step.

The `bonding` driver is already loaded, but no `bond0` exists yet. You build it. The segments have no switch that speaks LACP, so mode 4 cannot be built here. The hands-on steps use active-backup (mode 1), which needs nothing from the switch.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [One Link From Many Antennas](./course-01-one-link-from-many.md): what a bond is, and how to build one with `ip link`.
2. [Bonding Modes And Failover](./course-02-modes-and-failover.md): the three common modes, link monitoring, and a failover you trigger yourself.
3. [Make The Bond Last](./course-03-make-the-bond-last.md): runtime against persistent configuration, real redundancy, and your mission.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): a recap, your missions, and cleaning up.

## Why this matters

Bonding is how a Linux server survives a pulled cable or a failed network card without anyone noticing. The exam asks you to build a bond, put it in the right mode, and prove which member is active. The same habits, reading the kernel's own state file and checking before you trust, help with every network device in this course.
