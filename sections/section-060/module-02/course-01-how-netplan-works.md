# How Netplan Works

Astronaut, Netplan is not the officer who sets the antennas. It is the clerk who reads your flight manual and writes the detailed orders for that officer. This part shows how that hand-over works, the four commands that drive it, and how to read what Netplan sees right now.

## Netplan is a front end

**Netplan** is the Ubuntu way of describing network configuration. You write **YAML** files under `/etc/netplan/`. YAML is a plain-text format that uses indentation to show which setting belongs to which.

### From YAML to a live network

The `netplan` command reads all the files, merges them, and **renders** the low-level configuration for a **backend renderer**. That renderer is `systemd-networkd` (the default on Ubuntu Server) or `NetworkManager` (the default on Ubuntu Desktop). You do not edit the renderer's files directly; Netplan generates them.

```mermaid
flowchart LR
    Y["/etc/netplan/*.yaml"] -->|"netplan generate"| R["Renderer files"]
    R -->|"netplan apply"| B["systemd-networkd"]
    B -->|"sets"| K["Kernel"]
```

Netplan reads every YAML file in `/etc/netplan/`, writes files for the renderer, and the renderer (here `systemd-networkd`) sets the addresses in the kernel.

### Declarative: describe the end result

The style is **declarative**. The YAML states the desired end result: this interface has this address, this route, these DNS (Domain Name System, the galaxy-wide directory of call signs) servers. Netplan then makes the system match. That is the opposite of `ip` or `nmcli`, where you give one order at a time.

A minimal file looks like this:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
```

`network:` and `version: 2` are always at the top. Under a device category (`ethernets`, `bonds`, `bridges`, `vlans`, `wifis` and others), each interface is a key, with its settings nested beneath it.

### One of several persistent layers

Netplan, NetworkManager keyfiles, raw `systemd-networkd` `.network` files and the old `ifupdown` `/etc/network/interfaces` all keep the same addresses, routes and DNS servers on disk. They are different front ends with the same end result on the wire.

On Ubuntu, Netplan is the one in charge. Setting `renderer: NetworkManager` makes `nmcli` show the profiles Netplan generated. Cloud images configure the primary interface through `50-cloud-init.yaml`. A production host usually adds its own higher-numbered file, or replaces the cloud-init networking and turns it off.

## The `netplan` command

Four subcommands match four stages on the way from YAML to a live network. Knowing which ones touch the running network keeps you safe.

### The four stages

| Command | Does | Touches the running network? |
|---|---|---|
| `netplan get [path]` | parse and merge every file, print the result | no |
| `netplan generate` | translate the merged YAML into backend files (`/run/systemd/network/…`) | no |
| `netplan try` | apply, then a 120-second countdown; Enter keeps it, timeout **reverts** | yes, reversibly |
| `netplan apply` | render and tell the backend to adopt it, now, no undo | yes |

A simple way to remember it: **get** to see, **generate** to translate, **try** to apply with an undo, **apply** to commit. `netplan get` also works as a syntax check: a broken file makes it print an error instead of the configuration.

## Reading the merged configuration

`/etc/netplan/` can hold several files. `netplan get` parses them all, merges them, and prints the combined result.

### What Netplan sees right now

<!-- astrona:playground:renew -->

Print the merged configuration:

```sh
sudo netplan get
```

Expect the management interface's cloud-init configuration and nothing for the spare interface:

```text
network:
  version: 2
  ethernets:
    enp1s0:
      dhcp4: true
```

Only `enp1s0` (the interface that carries your SSH, or Secure Shell, session) is configured, by `/etc/netplan/50-cloud-init.yaml`. The spare interface is missing: Netplan does not manage it, because no file mentions it.

## Common pitfalls

> [!WARNING]
> - **Editing the rendered files.** Anything under `/run/systemd/network/` is written again on the next `netplan generate`. Edit the YAML in `/etc/netplan/`.
> - **Touching the cloud-init file.** `50-cloud-init.yaml` configures the interface your session runs on. Add your own higher-numbered file instead.
> - **Thinking `netplan get` applies anything.** It only reads and merges. Nothing on the network changes.
