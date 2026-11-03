# Persistent Network Managers

Astronaut, every address you set with `ip addr add` or `ip route add` is chalked on the console. It works right now, but the next restart wipes it clean. To make a setting stick, someone has to write it into the flight manual and read it back at every start-up.

On Linux that someone is a network manager. This module is about **NetworkManager**, driven from the command line with **`nmcli`**. Think of NetworkManager as a communications officer: it reads saved orders from disk and sets each antenna (network interface) to match them, at every boot.

## Learning objectives

After this module you can:

- Explain why `ip addr` and `ip route` changes do not survive a reboot, and which system makes them persistent.
- Describe the split in NetworkManager between devices and connection profiles, and read `nmcli device status` and `nmcli connection show`.
- Create a static connection profile with `nmcli connection add` and activate it with `nmcli connection up`.
- Change a profile's addressing, DNS (Domain Name System, the galaxy-wide directory of call signs) servers and autoconnect with `nmcli connection modify`, and explain why the profile must be activated again.
- Find a profile's keyfile under `/etc/NetworkManager/system-connections/` and reload it after a hand edit.
- Explain `managed` and `unmanaged` devices, and why only one tool should own an interface.

## Before you start

Every mission starts with a pre-flight check. Make sure you know the basics below and know what waits in your playground before you open the first part.

### What you should already know

- **Addresses and prefixes.** An interface name such as `enp2s0`, an address with its prefix length such as `192.168.120.50/24`, what a default gateway is, and what a DNS server does.
- **The shell.** You can open a shell, use `sudo`, and read a simple INI-style file (sections in `[brackets]`, then `key=value` lines).

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine. Open a shell on it with `astrona ssh networkmanager-nmcli-playground`.

- **NetworkManager** is installed and running, but a rule in `/etc/NetworkManager/conf.d/10-managed.conf` lets it manage **only one spare interface**. That interface sits on the isolated `192.168.120.0/24` segment.
- The spare interface has **no connection profile yet**. Building one is your job. Find its name with `ip -br link` or `nmcli device status`: it is the one shown as `disconnected`, not `unmanaged`.
- The **management interface** carries your SSH (Secure Shell, a sealed communications channel between two ships) session. NetworkManager leaves it `unmanaged`, so no `nmcli` command in this module can cut you off.
- The segment has **no DHCP (Dynamic Host Configuration Protocol, the harbour master who hands out call signs) server and no router**. Static (`manual`) addressing is the realistic case here.
- `nmcli`, `nmtui` and `ip` are installed, and `sudo` needs no password.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Devices And Connection Profiles](./course-01-devices-and-profiles.md): why runtime settings vanish, and how NetworkManager splits devices from profiles.
2. [Create A Static Profile](./course-02-create-a-static-profile.md): build a profile with `nmcli`, activate it, and read its keyfile on disk.
3. [Change, Reactivate And Keep A Profile](./course-03-change-and-reactivate.md): modify a profile, switch methods, control autoconnect, survive a reboot and spot a second manager.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, a self-check and cleanup.

## Why this matters

The exam often asks for a network setting that is still there after a reboot. A setting made only with `ip` passes a quick look and then fails the moment the machine restarts. Knowing how to write a profile, activate it and prove it is on disk is what turns a working change into a lasting one.
