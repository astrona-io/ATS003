# firewalld Zones and Services

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-030/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-030/module-02/playground
> astrona destroy firewalld-zones-playground
> ```

**firewalld** is a service that manages the Linux host firewall through a higher-level model than raw rules. You do not write individual filter rules with it. You tell it *which interface belongs to which trust level* and *which services should be reachable there*, and it generates the low-level rules. On current distributions those low-level rules are **nftables** rules — the subject of the previous module — so firewalld sits directly on top of what you have already seen. Its command-line front end is `firewall-cmd`.

It is called **dynamic** because a change applies without tearing down and rebuilding the whole ruleset: existing connections are left alone while the new rules slot in.

Two ideas carry most of firewalld:

- A **zone** is a named trust level — `public`, `internal`, `trusted`, `drop`, and others — bound to one or more interfaces or source addresses, each carrying its own list of what is allowed. An incoming packet is handled by the zone its **incoming interface** (or source address) is bound to.
- A **service** is a named bundle of ports and protocols — `ssh` is TCP 22, `http` is TCP 80, `https` is TCP 443. Allowing a service in a zone opens its ports there without you having to remember the numbers.

## How this module is organised

Work through the parts in order. Each is a single sitting, front-loads *why* the concept matters, and ends with the one line worth memorising for the exam. Every part has hands-on **Try it** checkpoints you run on the playground VM.

1. **[Architecture and the nftables backend](./course-01-architecture-and-backends.md)** — the daemon, `firewall-cmd`, the two config directories, what "dynamic" actually buys you, and the `table inet firewalld` that firewalld generates underneath.
2. **[Zones](./course-02-zones.md)** — a zone as a named policy, all the built-in zones and their targets, and the exact rule for how a packet's zone is chosen (source beats interface beats default).
3. **[Services, ports, and rich rules](./course-03-services-ports-richrules.md)** — what a service definition contains, `--add-service` vs `--add-port`, port ranges, forward ports, and rich rules for finer-grained allow/deny.
4. **[Runtime, permanent, and operations](./course-04-runtime-permanent-operations.md)** — the runtime/permanent split in depth, `--reload` vs `--complete-reload` vs `--runtime-to-permanent`, interface-binding persistence, panic mode, and the full pitfalls list.

## Learning objectives

After this module you can:

- Explain what firewalld adds on top of the kernel firewall, and what "dynamic" means for applying changes.
- Name firewalld's two configuration directories and which one you edit; name the two backends and which is current.
- Describe the built-in zones and their targets, and state the precedence rule for how a packet's zone is chosen.
- Read the default zone and the active zones with `firewall-cmd`, and list the services and ports a zone allows with `--list-all`.
- Open a port, a port range, and a named service in a zone — at runtime and persistently — and explain the `--permanent` / `--reload` split, including which commands touch both.
- Write a rich rule that allows one source network to one service, with logging.
- Assign an interface to a zone with `--change-interface`, bind a source address to a zone, and explain what makes each binding survive a reboot.
- Explain how firewalld relates to the nftables ruleset underneath it, and why hand-written `nft` rules conflict with it.

## Before you start

This module assumes you can open a shell, run commands with `sudo`, and know what a TCP port and an IPv4 address are. The nftables module is useful background — firewalld generates nftables rules — but is not required. Zone, service, and the runtime-versus-permanent split are all defined as they come up.

Open a shell on the playground VM with `astrona ssh astro-firewalld-zones-playground`; state-changing commands use `sudo`. The playground gives you:

- **firewalld running at its stock defaults**: default zone `public`, the `ssh` service allowed, nothing custom added.
- `firewall-cmd`, plus `curl` and `python3` for test traffic.
- Two local IPv4 addresses: the **management interface** carrying your SSH session — leave its zone alone — and **`192.168.90.10/24`** on a local dummy interface, used for the interface-to-zone and source-binding checkpoints. Find their kernel names with `ip -brief -4 addr show`.
- Password-less `sudo`.

Several checkpoints need a listener; start one with `python3 -m http.server 8080` in a second SSH session (or background it with `&`).

## Where this fits

firewalld is one of several front ends that can own the nftables ruleset — `ufw` on Debian/Ubuntu, a cloud provider's security groups, and a container runtime's own rules are others. Because firewalld regenerates its `table inet firewalld` on every reload, hand-written `nft` rules placed outside that table can be bypassed or overridden. **On a firewalld-managed host, change the firewall through `firewall-cmd`, not `nft`.**

Interface-to-zone binding is also where firewalld meets NetworkManager: NM can assign a zone per connection profile, so on an NM-managed system the zone often follows the connection rather than a `firewall-cmd` command.
