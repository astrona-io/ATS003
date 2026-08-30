# firewalld Zones and Services

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-030/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-030/module-02/playground
> astrona destroy firewalld-zones-playground
> ```

**firewalld** is a service that manages the Linux host firewall through a higher-level model than raw rules. You do not write individual filter rules with it. You tell it *which interface belongs to which trust level* and *which services should be reachable there*, and it generates the low-level rules. On current distributions those low-level rules are **nftables** rules — the subject of the previous module — so firewalld sits on top of what you have already seen. Its command-line front end is `firewall-cmd`.

It is called **dynamic** because a change applies without tearing down and rebuilding the whole ruleset: existing connections are left alone while the new rules slot in.

Two ideas carry most of firewalld:

- A **zone** is a named trust level — `public`, `internal`, `trusted`, `drop`, and others — bound to one or more interfaces or source addresses, each carrying its own list of what is allowed. An incoming packet is handled by the zone its **incoming interface** (or source address) is bound to.
- A **service** is a named bundle of ports and protocols — `ssh` is TCP 22, `http` is TCP 80, `https` is TCP 443. Allowing a service in a zone opens its ports there without you having to remember the numbers.

## Learning objectives

After this module you can:

- Explain what firewalld adds on top of the kernel firewall, and what "dynamic" means for applying changes.
- Describe how a packet's zone is chosen, and read the default zone and the active zones with `firewall-cmd`.
- List the services and ports a zone allows with `firewall-cmd --list-all`.
- Open a port, a port range, and a named service in a zone — at runtime and persistently — and explain the `--permanent` / `--reload` split.
- Assign an interface to a zone with `--change-interface` and confirm the move.
- Explain how firewalld relates to the nftables ruleset underneath it.

## Before you start

This module assumes you can open a shell, run commands with `sudo`, and know what a TCP port and an IPv4 address are. The nftables module is useful background — firewalld generates nftables rules — but is not required. Zone, service, and the runtime-versus-permanent split are all defined as they come up.

Open a shell on the playground VM with `astrona ssh astro-firewalld-zones-playground`; state-changing commands use `sudo`. The playground gives you:

- **firewalld running at its stock defaults**: default zone `public`, the `ssh` service allowed, nothing custom added.
- `firewall-cmd`, plus `curl` and `python3` for test traffic.
- Two local IPv4 addresses: the **management interface** carrying your SSH session — leave its zone alone — and **`192.168.90.10/24`** on an isolated segment, used for the interface-to-zone checkpoint. Find their kernel names with `ip -brief -4 addr show`.
- Password-less `sudo`.

Two checkpoints need a listener; start one with `python3 -m http.server 8080` in a second SSH session (or background it with `&`).

## Where this fits

firewalld is one of several front ends that can own the nftables ruleset — `ufw` on Debian/Ubuntu, a cloud provider's security groups, and a container runtime's own rules are others. Because firewalld regenerates its `table inet firewalld` on every reload, hand-written `nft` rules placed outside that table can be bypassed or overridden. **On a firewalld-managed host, change the firewall through `firewall-cmd`, not `nft`.**

Interface-to-zone binding is also where firewalld meets NetworkManager: NM can assign a zone per connection profile, so on an NM-managed system the zone often follows the connection rather than a `firewall-cmd` command.

## Reading `firewall-cmd`

`firewall-cmd` flags fall into three groups, and almost every command is one flag from the first two plus optionally one from the third:

| Group | Flags | Purpose |
|---|---|---|
| **Query** | `--state`, `--get-default-zone`, `--get-active-zones`, `--list-all`, `--list-services`, `--list-ports` | read current state; change nothing |
| **Change** | `--add-service=`, `--add-port=`, `--remove-service=`, `--change-interface=`, `--set-default-zone=` | modify a zone |
| **Scope** | `--permanent`, `--reload`, `--runtime-to-permanent` | *where* a change lands and how it is applied |

A change with no scope flag hits the **running** ruleset only. `--permanent` writes the **on-disk** config instead and does not touch the running ruleset until `--reload`. Most change and list flags take `--zone=<name>`; without it they act on the default zone.

Three query flags orient you before you touch anything:

- `firewall-cmd --state` — is the daemon running.
- `firewall-cmd --get-default-zone` — the zone applied to any interface not assigned elsewhere.
- `firewall-cmd --get-active-zones` — every zone that currently has an interface or source bound to it, and what is bound.

> [!TIP]
> **Try it — where does firewalld stand right now**
>
> ```sh
> sudo firewall-cmd --state
> sudo firewall-cmd --get-default-zone
> sudo firewall-cmd --get-active-zones
> ```
>
> Expect something like:
>
> ```text
> running
> public
> public
>   interfaces: enp0s1 enp0s2
> ```
>
> The daemon is `running`, the default zone is `public`, and both of the VM's interfaces are in `public` — neither has been assigned elsewhere, so both fall into the default. Interface names vary.

## What a zone allows

A zone is a policy: a list of allowed services, allowed ports, a few other settings, and a **target** (what to do with everything else — normally `default`, which means reject). `firewall-cmd --zone=<name> --list-all` prints the whole policy for one zone; with no `--zone` it shows the default zone.

> [!TIP]
> **Try it — read the public zone's policy**
>
> ```sh
> sudo firewall-cmd --zone=public --list-all
> ```
>
> Expect something like:
>
> ```text
> public (active)
>   target: default
>   interfaces: enp0s1 enp0s2
>   services: dhcpv6-client ssh
>   ports:
>   ...
> ```
>
> `services: … ssh` is why your SSH session survived firewalld starting — port 22 is allowed in the zone your management interface sits in. The `ports:` line is empty because nothing has opened a raw port yet.

## Opening a port

The most direct change is to open a single port or a range in a zone, given as `<number>[-<number>]/<protocol>`. Without `--permanent` it changes the **running** ruleset only — immediate, but gone on the next reload or restart.

To see it happen you need traffic that actually passes through a zone. Traffic to `127.0.0.1` does not — firewalld always allows loopback — so the checkpoint uses the VM's other address, `192.168.90.10`, whose interface is in `public`. Start a listener first:

```sh
python3 -m http.server 8080
```

> [!TIP]
> **Try it — a port is closed, then open it**
>
> From a second SSH session (or with the listener backgrounded by `&`):
>
> ```sh
> curl -sS --max-time 3 http://192.168.90.10:8080/ ; echo "exit: $?"
> sudo firewall-cmd --zone=public --add-port=8080/tcp
> curl -sS --max-time 3 http://192.168.90.10:8080/ | head -c 40 ; echo
> ```
>
> Expect the first `curl` to time out and the second to succeed:
>
> ```text
> curl: (28) Operation timed out after 3001 milliseconds
> exit: 28
> <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN
> ```
>
> The listener was running the whole time; only the zone changed. `public` had no rule for TCP 8080, so the request was rejected until `--add-port` allowed it. This change is runtime-only — remember that for the next checkpoint.

## Runtime versus permanent

Every `firewall-cmd` change lands in one of two places:

- **Runtime** (the default) — the live ruleset. Takes effect at once. Discarded by `firewall-cmd --reload` and lost on service restart or reboot.
- **Permanent** (`--permanent`) — the on-disk configuration. Does **not** affect the live ruleset until `firewall-cmd --reload` reads it back in.

So `--permanent` without `--reload` looks like nothing happened, and a plain runtime change looks permanent until the next reload wipes it. `firewall-cmd --runtime-to-permanent` copies the entire current runtime set to disk in one step.

> [!TIP]
> **Try it — add a service permanently and watch the reload**
>
> ```sh
> sudo firewall-cmd --permanent --zone=public --add-service=http
> sudo firewall-cmd --zone=public --list-services
> sudo firewall-cmd --reload
> sudo firewall-cmd --zone=public --list-services
> ```
>
> Expect `http` to be **absent** from the first listing and **present** after the reload:
>
> ```text
> dhcpv6-client ssh
> dhcpv6-client ssh http
> ```
>
> `--list-services` reads the runtime config, and `--permanent` did not touch that — only `--reload` applied it. The same reload also dropped the runtime-only `8080/tcp` port from the previous checkpoint: check with `sudo firewall-cmd --zone=public --list-ports` and it is gone.

## Assigning an interface to a zone

An interface lands in the default zone unless you put it somewhere else. `firewall-cmd --zone=<name> --change-interface=<dev>` moves an interface into a zone (and out of whatever zone it was in). Different zones allow different things — `internal` is more permissive than `public`; `drop` allows nothing and sends no reply.

Whether that binding survives a reboot depends on what manages the interface: NetworkManager stores it on the connection profile, otherwise firewalld records it — but an interface configured only at runtime takes its zone binding down with it on reboot.

> [!TIP]
> **Try it — move the spare interface into another zone**
>
> Use the kernel name of the `192.168.90.10` interface (from `ip -brief -4 addr show`; the examples call it `enp0s2`). **Do not** run this against the management interface — moving it to a zone without `ssh` cuts your session.
>
> ```sh
> sudo firewall-cmd --zone=internal --change-interface=enp0s2
> sudo firewall-cmd --get-active-zones
> ```
>
> Expect the interface to have moved:
>
> ```text
> internal
>   interfaces: enp0s2
> public
>   interfaces: enp0s1
> ```
>
> `enp0s2` is now handled by the `internal` zone's policy; `enp0s1` (your SSH interface) stays in `public`. A packet arriving on `192.168.90.10` is now matched against `internal`, not `public`.

## What firewalld is doing underneath

firewalld does not filter packets itself. It compiles your zones, services, and ports into **nftables** rules and loads them. Everything from the checkpoints above is visible in the same `nft list ruleset` output from the previous module.

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
> 	chain filter_IN_internal {
> 		...
> 	}
> }
> ```
>
> The `filter_IN_public` and `filter_IN_internal` chains are the zones you have been editing, expressed as nftables. `firewall-cmd` is a rule *generator*; the kernel firewall is still nftables.

> [!WARNING]
> **Common pitfalls**
>
> - **`--permanent` without `--reload`.** The change is on disk but not live. `--list-all` and `--list-services` read the runtime config, so the change seems to have vanished until you reload.
> - **A runtime change treated as saved.** Anything added without `--permanent` is gone after `--reload`, a service restart, or a reboot. Use `--runtime-to-permanent` to keep the current set.
> - **Locking yourself out.** Removing `ssh` from the zone on your management interface, `--set-default-zone=drop`, moving that interface to a closed zone, or `--panic-on` all cut the SSH session. Change zones on other interfaces, and keep `ssh` allowed where you connect.
> - **Expecting a zone to apply everywhere.** A zone only governs traffic whose incoming interface or source address is bound to it. An interface you never assigned is in the *default* zone, not the one you were editing.
> - **Editing `nft` rules on a firewalld host.** firewalld overwrites its table on reload. Manage the firewall with `firewall-cmd`.
