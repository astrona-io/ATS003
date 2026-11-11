# Dynamic Addressing with DHCP

Astronaut, the previous modules painted call signs on the hull by hand. On many ships a harbour master hands them out instead. **DHCP** (Dynamic Host Configuration Protocol) is that harbour master: a ship arrives, asks for a call sign, and receives one together with the lane to the rest of the galaxy and the directory to call. This module shows you the conversation, how to turn it on in Netplan, and how to stop a lease from changing things you want to keep.

## Learning objectives

After this module you can:

- Describe the four steps of a DHCP exchange (Discover, Offer, Request, Acknowledge) and what a lease carries.
- Explain lease time and renewal.
- Turn on DHCP for an interface with `dhcp4: true` in Netplan and prove the result with `ip`, `networkctl` and the lease file.
- Use `dhcp4-overrides` to ignore the routes, the DNS servers or the host name from a lease, and to change the route metric.
- Renew a lease by hand and read the DHCP packets with `tcpdump`.

## Before you start

A short pre-flight check: the knowledge this module expects, and what is waiting in your playground.

### What you should already know

- **Addresses and routes.** An IP address is the ship's call sign, and the default route is the lane for "everywhere else".
- **Netplan.** A Netplan file is the flight manual for the communications array, and `netplan apply` makes the ship read it.

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine. Open a shell with `astrona ssh dhcp-client-playground`. The ship holds a small harbour inside it, built from a linked pair of virtual antennas:

| Item | What it is |
| --- | --- |
| `dhcpsrv0` | the harbour master's antenna, `10.77.0.1/24`, answering DHCP requests with `systemd-networkd` |
| `dhcp0` | your client antenna, linked to `dhcpsrv0`, with no configuration yet |
| lease pool | `10.77.0.100` to `10.77.0.149`, lease time 10 minutes |

The management interface carries your own session. Never change it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [The Lease Conversation](./course-01-the-lease-conversation.md): the four steps and what a lease contains.
2. [A DHCP Client In Netplan](./course-02-a-dhcp-client-in-netplan.md): turn it on and prove it.
3. [Overrides And Renewals](./course-03-overrides-and-renewals.md): keep the parts of a lease you want and refuse the rest.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, a self-check and cleanup.

## Why this matters

Most real ships get their addresses from DHCP, and the exam asks you to configure both static and dynamic addressing. A dynamic address that also installs the wrong default route can cut a machine off, so you must know what a lease changes.

<!-- curriculum-practice -->
## Practice and assessment

- [DHCP Client Lab](labs/lab-01/question.md): Turn on a DHCP client for an interface in Netplan; Keep the address from a lease and refuse its routes and DNS servers; Prove the lease with ip, networkctl and resolvectl.
- [Core Host Configurations Capstone Lab](../capstone/labs/lab-01/question.md): Add a secondary IPv4 and a static IPv6 address beside the management address; Make both addresses survive a reboot in Netplan or NetworkManager configuration; Map the host name app-srv1 to its new address in /etc/hosts, forward and reverse.
