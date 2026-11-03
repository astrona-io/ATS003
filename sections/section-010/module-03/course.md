# Discovering Your Public IP Address

Astronaut, your ship can carry one call sign inside the home fleet and appear under a different call sign to the rest of the galaxy. A Linux machine works the same way. The address on its network interface is often not the address a remote server sees. The gap between the two comes from **NAT (network address translation)**: a relay station that swaps every outgoing call sign for its own.

This module is about measuring that gap. There are two questions, with two different answers:

- *What address is on my network card?* You answer this on the machine itself with `ip addr show`. On a home, office or cloud network it is usually a **private** address.
- *What address does a remote server see when I connect to it?* You cannot answer this on the machine itself. The machine has to ask a service on the internet. This is the **public egress address**, and it normally belongs to a router or gateway between the machine and the internet, not to the machine.

## Learning objectives

After this module you can:

- Decide whether an address from `ip addr show` is private (one of the RFC 1918 ranges) or public, by matching it to the three private blocks.
- Explain why the address on your interface can differ from the address an internet server sees, using NAT and SNAT.
- Read `ip route show` to find the default gateway, and explain why that gateway address is normally private, not your public address.
- Ask an outside HTTP or DNS service for the public egress address, and add a timeout so a blocked request fails fast instead of hanging.
- Explain why HTTP-based and DNS-based discovery can return different addresses.
- Say what a discovered public address does *not* tell you about whether the internet can reach the machine.

## Before you start

Check that you have the knowledge this module expects, and know what is waiting in your playground.

### What you should already know

- **How to use a shell.** You can open a terminal and run commands.
- **What an address and an interface look like.** You have seen a dotted IPv4 address such as `192.168.1.50`, and you know an interface has a name such as `enp0s1`.

Private and public ranges, NAT, SNAT, the default gateway and the egress address are all explained when they come up. Discovery uses `curl` and `dig`, and both are already installed.

### What is in your playground

Your playground is a training ship in the simulator: one Ubuntu 24.04 virtual machine. Open a terminal on it with `astrona ssh public-ip-playground`.

It sits on two private ranges at once, with no public address set anywhere on it:

| Interface | Address | Range |
| --- | --- | --- |
| The management interface | a private address that carries the **default route** | `10.0.0.0/8` |
| An extra interface, added by `bootstrap/prepare.sh` | `172.16.20.50/24` | `172.16.0.0/12` |

The tools `curl`, `dig` (from `dnsutils`) and `ip` (from `iproute2`) are installed. Whether the playground can reach the internet to *ask* for its egress address depends on how the environment was set up. The discovery step works either way: a request that times out is part of the lesson, not a fault to fix.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Private Call Signs And The Relay Station](./course-01-private-addresses-and-nat.md): the private address ranges, how NAT works, and why the default gateway is not your public address.
2. [Ask The Galaxy What It Sees](./course-02-ask-what-the-internet-sees.md): discovering the public egress address over HTTP and DNS, IPv4 against IPv6, and what the answer does not prove.
3. [Wrap-Up: Mission Debrief](./course-03-wrap-up.md)

## Why this matters

Firewall requests, allow lists at a partner company and many cloud settings ask for "your public address". If you hand over the private address from your interface, nothing works, and nobody can see why.

The exam expects you to know which address is which, how to find each one quickly from a terminal, and what a discovered address does and does not prove.
