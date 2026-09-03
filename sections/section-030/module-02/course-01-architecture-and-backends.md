# Part 1 — Architecture and the nftables backend

> Prerequisite: the module landing page, [course.md](./course.md). Next: [Part 2 — Zones](./course-02-zones.md).

Before the zone-and-service model makes sense, it helps to see the machine it runs on: a long-lived daemon, a command-line client that just talks to it, two configuration directories with different jobs, and — underneath all of it — an ordinary nftables ruleset like the one you built by hand in the previous module. This part draws that picture so the rest of the module is "which knob," not "what is this thing."

## The daemon and its clients

**firewalld** is a `systemd` service (`firewalld.service`) that runs continuously. It holds the *current* firewall policy in memory and owns the kernel ruleset. You never edit the kernel ruleset directly — you ask the daemon to, and it recomputes and reloads.

Clients talk to the daemon over **D-Bus**:

| Client | Use |
|---|---|
| `firewall-cmd` | the everyday command-line client — everything in this module |
| `firewall-config` | a GTK graphical client |
| `firewall-offline-cmd` | edits the on-disk config **while the daemon is stopped** (recovery, image building) |
| `firewall-applet` | a tray indicator |

Because the state lives in the daemon, `firewall-cmd` commands are requests, not file edits. That is what makes the runtime-versus-permanent split (Part 4) necessary: a request can change the *running* daemon state, the *on-disk* config, or both.

## Two configuration directories

firewalld reads zone, service, and other definitions from two places, in this order:

| Directory | Contains | Do you edit it? |
|---|---|---|
| `/usr/lib/firewalld/` | the **stock** definitions shipped by the package — every built-in zone and the ~100 predefined services | **No.** A package update overwrites it. |
| `/etc/firewalld/` | your **local** additions and overrides | Yes — directly, or (better) via `firewall-cmd --permanent` |

A file in `/etc/firewalld/` with the same name as one in `/usr/lib/firewalld/` **replaces** it. This is how you customise a built-in zone: firewalld copies it to `/etc/firewalld/zones/` the first time you change it permanently, and edits the copy.

Each definition is a small XML file. A zone is `/etc/firewalld/zones/<name>.xml`; a service is `/etc/firewalld/services/<name>.xml`. You rarely write these by hand — `firewall-cmd --permanent` does — but knowing where they live makes "did my permanent change actually land" answerable with `ls` and `cat`.

## What "dynamic" actually means

The predecessor pattern (the old `iptables` init script) applied a firewall by **flushing every rule and re-adding the whole set**. During that flush the box was briefly unprotected, and every existing connection's conntrack state that depended on a rule was disrupted.

firewalld is **dynamic**: when you change one zone, it computes the delta and splices only the changed rules into the live ruleset. Nothing is flushed, established connections are undisturbed, and there is no unprotected window. This is why you can safely `--add-service=https` on a production box in the middle of the day.

Two reload levels:

- `firewall-cmd --reload` — re-read the permanent config and apply it, **keeping** connection-tracking state. The normal reload.
- `firewall-cmd --complete-reload` — tear down everything including conntrack state. For when the ruleset is wedged; it *will* break active connections.

## Underneath: it is just nftables

firewalld does not filter packets itself. It compiles your zones, services, ports, and rich rules into **nftables** rules and loads them into a single table it owns: `table inet firewalld`. On older systems (or when `FirewallBackend=iptables` is set in `/etc/firewalld/firewalld.conf`) it emits `iptables` rules instead, but `nftables` is the default on every current distribution.

The generated table has a predictable chain layout:

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

Note the priority: `filter + 10` (i.e. 10), so firewalld's base chain runs *after* a plain `priority 0` chain. The `filter_INPUT_ZONES` chain is where a packet is matched to its zone (Part 2) and sent to that zone's chain.

> [!TIP]
> **Try it — find firewalld's rules in the nftables ruleset**
>
> ```sh
> sudo nft list table inet firewalld | head -n 30
> ```
>
> Expect a large table with per-zone chains:
>
> ```text
> table inet firewalld {
> 	chain filter_INPUT {
> 		type filter hook input priority filter + 10; policy accept;
> 		...
> 		jump filter_INPUT_ZONES
> 	}
> 	chain filter_IN_public {
> 		...
> 	}
> }
> ```
>
> Every `firewall-cmd` change you make in the rest of this module shows up as edits inside this table. `firewall-cmd` is a rule *generator*; the kernel firewall is still nftables.

## Other front ends own the same ruleset

firewalld is not the only thing that wants to own nftables:

- `ufw` (Debian/Ubuntu) — a different front end with the same job.
- **NetworkManager** — can assign a zone per connection, feeding firewalld.
- **Docker / Podman / Kubernetes** — insert their own NAT and filter rules.
- A cloud provider's **security groups** — filter *before* the packet reaches your host at all.

Because firewalld rewrites `table inet firewalld` on every reload, `nft` rules you add by hand in your own table still exist but can be evaluated in an order you did not intend, and firewalld will not know about them. On a firewalld host, manage the firewall with `firewall-cmd`.

> *firewalld is a daemon that compiles zones and services into an nftables table called `table inet firewalld`; `firewall-cmd` only sends it requests. "Dynamic" means changes splice in without a flush, so live connections survive.*

## Reference

- `man 1 firewall-cmd` — the client; skim the "OPTIONS" groups once to see the shape of the whole tool.
- `man 5 firewalld.conf` — `DefaultZone`, `FirewallBackend`, `CleanupOnExit`, and other daemon-wide settings.
- `man 5 firewalld.zone` and `man 5 firewalld.service` — the XML schema for the files in `/etc/firewalld/`.
- **firewalld.org documentation** (`https://firewalld.org/documentation/`) — concept pages for the daemon, D-Bus API, and backends.
