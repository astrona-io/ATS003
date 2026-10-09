# Architecture And The nftables Backend

Astronaut, before zones and services make sense, it helps to see the machine they run on. firewalld is a long-running station on your ship, a console that only sends it requests, two configuration directories with different jobs, and, underneath it all, an ordinary nftables ruleset.

This part draws that picture, so the rest of the module is about "which switch", not "what is this thing".

## The daemon and its clients

firewalld is not a command you run once. It is a service that keeps running and holds the firewall policy in memory. This section shows the service and the tools that talk to it.

### A station that is always staffed

**firewalld** is a `systemd` service (`firewalld.service`), a station the ship's duty officer keeps staffed at all times. It holds the *current* firewall policy in memory and owns the kernel ruleset. You never edit the kernel ruleset directly: you ask the daemon to, and it works out the new rules and loads them.

### The clients

Clients talk to the daemon over **D-Bus**, the message bus programs on a Linux machine use to talk to each other:

| Client | Use |
|---|---|
| `firewall-cmd` | the everyday command-line client, used for everything in this module |
| `firewall-config` | a graphical client |
| `firewall-offline-cmd` | edits the configuration on disk **while the daemon is stopped** (recovery, building images) |
| `firewall-applet` | a small icon for the desktop tray |

Because the state lives in the daemon, `firewall-cmd` commands are requests, not file edits. That is why firewalld has a runtime and a permanent configuration: a request can change the *running* state, the *saved* configuration on disk, or both.

## Two configuration directories

firewalld reads zone, service and other definitions from two places. Knowing which is which tells you where your changes land and which files never to touch.

### Stock files and your files

| Directory | Contains | Do you edit it? |
|---|---|---|
| `/usr/lib/firewalld/` | the **stock** definitions shipped with the package: every built-in zone and about 100 ready-made services | **No.** A package update overwrites it. |
| `/etc/firewalld/` | your **local** additions and changes | Yes, directly or (better) with `firewall-cmd --permanent` |

A file in `/etc/firewalld/` with the same name as one in `/usr/lib/firewalld/` **replaces** it. This is how you change a built-in zone: firewalld copies it to `/etc/firewalld/zones/` the first time you change it permanently, and edits the copy.

### What the files look like

Each definition is a small XML file. XML is a text format of nested tags. A zone is `/etc/firewalld/zones/<name>.xml`; a service is `/etc/firewalld/services/<name>.xml`. You rarely write these by hand, because `firewall-cmd --permanent` does it for you. But knowing where they live lets you answer "did my permanent change really land?" with `ls` and `cat`.

## What "dynamic" really means

The older way to manage a firewall had a weak moment every time it changed. firewalld removes that moment. This section explains how, and the two reload commands.

### Changes without a gap

The older pattern, the `iptables` start-up script, applied a firewall by **flushing every rule and adding the whole set again**. During that flush the machine was briefly unprotected, and every connection whose tracking depended on a rule was disturbed.

firewalld is **dynamic**. When you change one zone, it works out the difference and splices only the changed rules into the live ruleset. Nothing is flushed, connections in progress are not disturbed, and there is no unprotected gap. That is why you can safely run `--add-service=https` on a production machine in the middle of the day.

### Two reload levels

- `firewall-cmd --reload` reads the permanent configuration again and applies it, **keeping** the connection tracking state, the shield's memory of conversations in progress. This is the normal reload.
- `firewall-cmd --complete-reload` tears everything down, including the connection tracking state. Use it only when the ruleset is stuck: it *will* break connections in progress.

## Underneath, it is just nftables

firewalld does not filter packets itself. It writes your zones, services, ports and rich rules as **nftables** rules, the kernel's own shield program, into one table it owns: `table inet firewalld`.

On older systems, or when `FirewallBackend=iptables` is set in `/etc/firewalld/firewalld.conf`, it writes `iptables` rules instead. `nftables` is the default on every current distribution.

### The table firewalld writes

The table has a predictable layout of chains (checkpoints):

```text
table inet firewalld {
	chain filter_INPUT {                 # base chain, hook input, priority filter + 10
		ct state established,related accept
		iifname "lo" accept
		jump filter_INPUT_ZONES          # dispatch to the right per-zone chain
		reject with icmpx type admin-prohibited
	}
	chain filter_IN_public { ... }        # the 'public' zone's allow list
	chain filter_IN_internal { ... }      # the 'internal' zone's allow list
	...
}
```

Note the priority: `filter + 10`, that is 10. So firewalld's base chain runs *after* a plain `priority 0` chain. The `filter_INPUT_ZONES` chain is where a packet is matched to its zone and sent on to that zone's chain.

### Find firewalld's rules in the ruleset

<!-- astrona:playground:renew -->

List the first lines of firewalld's table on your playground:

```sh
sudo nft list table inet firewalld | head -n 30
```

You see a large table with one chain per zone:

```text
table inet firewalld {
	chain filter_INPUT {
		type filter hook input priority filter + 10; policy accept;
		...
		jump filter_INPUT_ZONES
	}
	chain filter_IN_public {
		...
	}
}
```

(The listing is shortened: the dots stand for lines left out.)

Every `firewall-cmd` change you make shows up as edits inside this table. `firewall-cmd` writes rules; the kernel firewall is still nftables.

## Other tools own the same ruleset

firewalld is not the only thing that wants to manage nftables. Knowing the others helps you spot a clash:

- `ufw` (Debian and Ubuntu) is a different front end with the same job.
- **NetworkManager**, a service that manages the network antennas, can assign a zone per connection and pass it to firewalld.
- **Docker, Podman and Kubernetes** add their own address translation and filter rules.
- A cloud provider's **security groups** filter *before* the packet even reaches your host.

Because firewalld rewrites `table inet firewalld` on every reload, `nft` rules you add by hand in your own table still exist, but they can be checked in an order you did not intend, they can be bypassed or overridden, and firewalld does not know about them. **On a firewalld host, change the firewall with `firewall-cmd`, not `nft`.**

## Common pitfalls

> [!WARNING]
> - **Editing files under `/usr/lib/firewalld/`.** A package update overwrites them. Your changes belong in `/etc/firewalld/`.
> - **Using `--complete-reload` as a normal reload.** It drops the connection tracking state and breaks connections in progress. Use `--reload`.
> - **Editing `nft` rules on a firewalld host.** firewalld rewrites its table on every reload and does not know about your rules. Use `firewall-cmd`.

> *firewalld is a daemon that turns zones and services into an nftables table called `table inet firewalld`; `firewall-cmd` only sends it requests. "Dynamic" means changes splice in without a flush, so live connections survive.*
