# Software Bridging

Astronaut, picture a docking hub in the middle of your ship. Every antenna plugged into it shares one local lane, and signals pass between them as if they were one network. That hub is a Linux **software bridge**: a virtual Layer 2 switch built into the kernel, the ship's core.

Like a physical switch, a bridge connects several network interfaces and forwards Ethernet frames between them by MAC address, the serial number stamped on each antenna. The interfaces attached to a bridge are its **bridge ports**. Bridges are the backbone of virtual machine and container networking, Linux routers and firewalls, and much more.

## Learning objectives

After this module you can:

- Explain what a Linux software bridge is, why it works at Layer 2, and why an IP address belongs on the bridge rather than on a port.
- Create a temporary bridge with `ip link`, attach an interface with `master`, and confirm membership with `bridge link show`.
- Describe how a bridge learns MAC addresses into its forwarding database (FDB), and read it with `bridge fdb show`.
- Explain how a Layer 2 loop forms and what STP does about it, and turn STP on or off for a bridge.
- Put an IP address on the bridge and check the result with `ip addr show`.
- Explain why a bridge made with `ip` is lost on reboot, and say how a bridge differs from a bond.

## Before you start

Every mission starts with a pre-flight check. Make sure you have the basics this module expects, and know what is waiting in your playground.

### What you should already know

- **A shell and `sudo`.** You can open a terminal and run a command with `sudo`, which borrows the captain's authority.
- **Interface names and addresses.** You have seen interface names like `enp0s2` and an IPv4 address with a prefix, such as `192.168.60.10/24`. Ethernet frame, MAC address, Layer 2 and Layer 3, ARP, DHCP and STP are explained when they first come up.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. Open a terminal on it with `astrona ssh linux-bridging-playground`.

It has three usable network interfaces:

- **The management interface.** It carries your SSH (Secure Shell) session, your link to mission control, and it holds an address. Leave it alone.
- **Two spare bridge-port interfaces.** Both are `DOWN`, both have no address, and both face the **same** isolated `192.168.60.0/24` segment. That is on purpose: it lets you build a real Layer 2 loop and watch STP break it.

No `br0` exists yet. The segment has no other host and no DHCP server, so learned forwarding entries and DHCP on a bridge cannot be shown here. The parts say so where each one comes up.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [A Switch Inside The Kernel](./course-01-a-switch-inside-the-kernel.md): Layer 2 against Layer 3, the two tools, and your first bridge with one port.
2. [How A Bridge Learns](./course-02-how-a-bridge-learns.md): the forwarding database, the address on the bridge, and DHCP.
3. [Loops And Spanning Tree](./course-03-loops-and-spanning-tree.md): a loop you build on purpose, STP, and taking a bridge apart.
4. [Make The Bridge Last](./course-04-make-the-bridge-last.md): runtime against persistent configuration, bridges against bonds, and your mission.
5. [Wrap-Up: Mission Debrief](./course-05-wrap-up.md): a recap, your missions, and cleaning up.

## Why this matters

Every virtual machine host and container platform you will ever manage depends on bridges. The exam asks you to build one, attach a port, and prove it forwards. Knowing where the address goes and how loops form saves you from the two mistakes that take whole networks down.
