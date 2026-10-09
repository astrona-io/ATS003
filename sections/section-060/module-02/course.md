# Netplan YAML Configurations

Astronaut, on an Ubuntu ship the flight manual for the communications array is written in YAML. **Netplan** reads that manual and hands the orders to the officer who actually sets the antennas. This module teaches you to write the manual, check it, and apply it without cutting yourself off from mission control.

## Learning objectives

After this module you can:

- Explain that Netplan is a declarative front end that renders YAML under `/etc/netplan/` for `systemd-networkd` or `NetworkManager`.
- Write a `network:` block for a static interface (`addresses`, `routes`, `nameservers`) with space-only indentation.
- Merge and inspect the effective configuration with `netplan get`.
- Render the backend files with `netplan generate` and read what Netplan produced.
- Apply a change safely with `netplan try` (automatic rollback) and permanently with `netplan apply`.
- Predict how several files in `/etc/netplan/` merge, and why file order matters.

## Before you start

A short pre-flight check: the knowledge this module expects, and what is waiting in your playground.

### What you should already know

- **Addresses and prefixes.** Interface names, an address with its prefix length such as `192.168.130.50/24`, what a default gateway is and what a DNS (Domain Name System, the galaxy-wide directory of call signs) server does.
- **The shell.** You can open a shell, use `sudo`, and edit a file with a text editor. YAML itself is explained in the parts.

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine. Open a shell on it with `astrona ssh netplan-yaml-playground`.

- **Netplan** runs natively here, with `systemd-networkd` as the renderer. `netplan`, `networkctl` and `ip` are installed, and `sudo` needs no password.
- One **spare interface** sits on the isolated `192.168.130.0/24` segment. There is no DHCP (Dynamic Host Configuration Protocol, the harbour master who hands out call signs) server and no router there, so static addressing is the realistic case. It has **no Netplan file yet**: writing one is the point. Its name is in `/root/lab-spare-iface` (or run `ip -br link`).
- The **management interface** keeps its own cloud-init Netplan file under `/etc/netplan/`. **Leave that file alone**: it configures the interface your SSH (Secure Shell, a sealed communications channel between two ships) session uses.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [How Netplan Works](./course-01-how-netplan-works.md): the declarative idea, the four `netplan` commands, and reading the merged configuration.
2. [Write And Render A Netplan File](./course-02-write-and-render.md): write an interface block, see the parser reject a tab, and read the files Netplan generates.
3. [Apply Safely And Merge Files](./course-03-apply-and-merge.md): apply with `netplan try`, and see how a later file overrides one key.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, a self-check and cleanup.

## Why this matters

On Ubuntu, Netplan is the layer that decides what the network looks like after every boot. A wrong indent or a careless `netplan apply` on a remote server can cut you off with no way back. Learning to check with `netplan get` and apply with `netplan try` keeps you in control.
