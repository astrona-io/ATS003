# Devices And Connection Profiles

Astronaut, a setting you type with `ip` lives only in the running kernel, the ship's core. Restart the ship and it is gone. This part shows which systems keep network settings on disk, and how NetworkManager organises what it keeps.

## Runtime settings and persistent settings

Addresses and routes set with `ip addr add` or `ip route add` live only in the running kernel. A reboot wipes them. Think of them as notes chalked on the console: useful now, gone at the next restart.

To make network configuration stick, a program must write it to disk and apply it again at every boot. That is the flight manual for the communications array. Linux has several programs that do this job:

- **NetworkManager**, the subject of this module.
- **systemd-networkd**, a small network service that is part of systemd.
- **Netplan**, an Ubuntu front end. You write YAML files, and Netplan turns them into settings for NetworkManager or systemd-networkd.
- **ifupdown**, the older system with `/etc/network/interfaces`.

Exactly one of them should own any given interface. Two officers giving the same antenna different orders never ends well.

## How NetworkManager thinks: devices and connections

NetworkManager keeps two kinds of things apart. Getting this split right makes every `nmcli` command easier to read.

### Device and connection profile

- A **device** is an interface the kernel has right now, such as `enp1s0`, `wlan0` or `bond0`. NetworkManager does not store settings on the device.
- A **connection** (or connection *profile*) is a named bundle of settings: addressing, DNS (Domain Name System, the galaxy-wide directory of call signs) servers, routes, which device it binds to, and whether it starts on its own. Profiles are what you create, edit and save.

One device can have several profiles on file. For example, a static profile for the office and a DHCP (Dynamic Host Configuration Protocol, the harbour master who hands out call signs) profile for anywhere else. Only one is **active** at a time. Bringing a profile "up" applies its settings to its device.

```mermaid
flowchart LR
    P["Profile: lab-static"] -->|"nmcli connection up"| D["Device: enp2s0"]
    D -->|"address set"| K["Kernel"]
```

The profile on disk holds the settings, `nmcli connection up` hands them to NetworkManager, and NetworkManager sets them on the device in the kernel.

### Other ways to drive the same profiles

`nmcli` is one way in. `nmtui` (a text menu), editing `.nmconnection` files by hand followed by `nmcli connection reload`, and configuration-management tools (for example the Ansible `nmcli` module) are others. They all drive the same profiles.

On Ubuntu, Netplan may be the front end, and it can be told to use NetworkManager as its renderer. On a host that NetworkManager manages, `nmcli` writes DNS servers into `/etc/resolv.conf` or hands them to `systemd-resolved`, the name lookup service.

## Reading `nmcli`

`nmcli` (NetworkManager command-line interface) is organised by **object**, then a command on that object. Once you know the objects, the commands read like short sentences.

### The objects

| Object | What it is | Common commands |
|---|---|---|
| `nmcli device` | interfaces the kernel has | `status`, `show`, `connect`, `disconnect`, `reapply` |
| `nmcli connection` | saved profiles | `show`, `add`, `modify`, `up`, `down`, `delete`, `reload` |
| `nmcli general` / `nmcli networking` | daemon and global state | `status`, `on`, `off` |

A simple way to remember it: **device** is what the kernel has right now; **connection** is what you saved to disk. `show` and `status` only read. `add`, `modify`, `up`, `down` and `delete` change things and need `sudo`. Most objects also take a short alias: `nmcli dev`, `nmcli con` or `nmcli c`.

## Devices and connections in your playground

The first thing to check is which devices NetworkManager can see and what state each one is in: `connected`, `disconnected` (managed, but no active profile), `unavailable`, or `unmanaged`.

### See what NetworkManager is managing

<!-- astrona:playground:renew -->

Run these two commands:

```sh
nmcli device status
nmcli connection show
```

Expect the spare interface managed with no profile, and the SSH (Secure Shell, a sealed communications channel between two ships) interface left alone:

```text
DEVICE  TYPE      STATE         CONNECTION
enp1s0  ethernet  unmanaged     --
enp2s0  ethernet  disconnected  --
lo      loopback  unmanaged     --

NAME  UUID  TYPE  DEVICE
```

`enp1s0` (your SSH interface) is `unmanaged`, so NetworkManager will not touch it. `enp2s0` is `disconnected`: managed, but with no connection profile, so it has no address. `nmcli connection show` is empty because nothing has been created yet.

Interface names vary between machines. Use your own names in every command that follows.

## Common pitfalls

> [!WARNING]
> - **Expecting `ip` changes to survive a reboot.** They live only in the running kernel. Write them to a profile to keep them.
> - **Two managers on one interface.** NetworkManager and systemd-networkd, Netplan or ifupdown all configuring the same interface makes it flap. Keep one owner per interface.
> - **Confusing a device with a profile.** The device is the interface; the profile is the saved settings. Commands that change settings work on the profile.
