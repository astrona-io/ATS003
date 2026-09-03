# Part 4 — Runtime, permanent, and operations

> Prerequisite: [Part 3 — Services, ports, and rich rules](./course-03-services-ports-richrules.md). This is the last part of the module — return to [course.md](./course.md), then the [section quiz](../quiz.md).

Every `firewall-cmd` change lands in one of two places, and mixing them up is the single most common firewalld mistake: a change that "did nothing" (permanent, not reloaded) or a change that "disappeared" (runtime, then reloaded). This part nails down the split, the commands that bridge it, what makes an interface binding survive a reboot, and the ways people lock themselves out.

## Runtime versus permanent

| | **Runtime** (default) | **Permanent** (`--permanent`) |
|---|---|---|
| Where it lands | the live daemon state / kernel ruleset | the XML files under `/etc/firewalld/` |
| Takes effect | immediately | **not until `firewall-cmd --reload`** |
| Survives `--reload` | **no** — reload discards runtime and re-reads permanent | yes |
| Survives reboot / `systemctl restart firewalld` | no | yes |
| Shown by `--list-all`, `--list-services` | yes (these read **runtime**) | only after a reload |

Two consequences trip people up constantly:

- `--permanent` **without** `--reload` looks like nothing happened — `--list-services` reads runtime, and runtime has not changed yet.
- A plain runtime change looks permanent — until the next `--reload`, service restart, or reboot silently wipes it.

## The bridging commands

| Command | Effect |
|---|---|
| `firewall-cmd --reload` | discard runtime, re-apply permanent config, **keep** conntrack state |
| `firewall-cmd --complete-reload` | as above but also drop conntrack state — breaks live connections; use only when wedged |
| `firewall-cmd --runtime-to-permanent` | copy the **entire** current runtime set to disk in one step — the "I tested it live, now save it" button |
| `firewall-cmd --set-default-zone=<z>` | **exception:** applies to runtime *and* permanent at once, no `--reload` needed |
| `firewall-cmd --check-config` | validate the permanent XML before a reload trips over it |

`--set-default-zone` doing both at once is a genuine special case worth remembering — most change flags do not.

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
> `--list-services` reads the runtime config, and `--permanent` did not touch that — only `--reload` applied it. The same reload also drops any runtime-only port from Part 3: check with `sudo firewall-cmd --zone=public --list-ports` and it is gone.

> [!TIP]
> **Try it — save a tested runtime change**
>
> ```sh
> sudo firewall-cmd --zone=public --add-port=9100/tcp     # runtime only
> sudo firewall-cmd --runtime-to-permanent                # commit everything runtime to disk
> sudo firewall-cmd --reload
> sudo firewall-cmd --zone=public --list-ports            # 9100/tcp is still there
> ```
>
> Without the `--runtime-to-permanent`, that `--reload` would have removed `9100/tcp`.

## What makes an interface-to-zone binding persist

An interface's zone can be recorded in three different places, and *which one* decides whether it survives a reboot:

| Managed by | Where the binding lives | Persists a reboot? |
|---|---|---|
| **NetworkManager** | the connection profile's `connection.zone` key | yes — NM re-applies it when it brings the link up |
| **firewalld directly** (`--permanent --zone=X --add-interface=dev`) | `/etc/firewalld/zones/X.xml` | yes — but only if *something else* also brings the interface up |
| **runtime only** (`--change-interface` with no `--permanent`) | daemon memory | **no** |

On a modern NM-managed host the practical rule is: set the zone on the *connection*, e.g. `nmcli connection modify <name> connection.zone internal`. A `firewall-cmd --change-interface` on top of that can be overridden the next time NM re-activates the link.

## Locking yourself out — the scenarios

> [!WARNING]
> Each of these cuts an active SSH session on the management interface:
>
> - **Removing `ssh` from the zone** that handles your management interface (`--remove-service=ssh`).
> - **`--set-default-zone=drop`** (or `block`) while your interface relies on the default zone.
> - **`--change-interface`** moving your management interface into a zone without `ssh`.
> - **A source binding** that puts your client's address into `drop`/`block`.
> - **`--panic-on`** — drops *all* traffic in and out immediately, no exceptions. `--panic-off` restores; `--query-panic` checks. There is no timer.
>
> Recovery on this throwaway VM is the serial console (`firewall-cmd --panic-off`, `firewall-cmd --reload`, or `systemctl restart firewalld` to drop runtime-only changes) or destroying and re-running the playground. On a real remote host, test firewall changes with a scheduled `--reload` or an "undo in N minutes" `at` job in place.

## Other operational bits

- **`firewall-cmd --direct ...`** — an escape hatch to inject raw `iptables`/`nft` rules into firewalld's chains. Avoid it: it bypasses the zone model and the rules are invisible to `--list-all`. Rich rules cover almost every case people reach `--direct` for.
- **`firewall-cmd --set-log-denied=all`** (then `--reload`) — logs rejected/dropped packets to the kernel log; `--get-log-denied` shows the current setting. Off by default.
- **`firewall-offline-cmd`** — same syntax as `firewall-cmd --permanent`, but edits `/etc/firewalld/` with the daemon **stopped**. For rescue mode and image builds.
- **`systemctl restart firewalld`** discards all runtime changes (same as a reboot for firewall state). `--reload` is almost always what you want instead.

## Common pitfalls

> [!WARNING]
>
> - **`--permanent` without `--reload`.** The change is on disk but not live. `--list-all` and `--list-services` read runtime, so the change seems to have vanished.
> - **A runtime change treated as saved.** Anything without `--permanent` is gone after `--reload`, `systemctl restart firewalld`, or a reboot. Use `--runtime-to-permanent` to keep the current set.
> - **Expecting `--reload` to be harmless.** It *discards* every runtime-only change. Save first.
> - **Locking yourself out.** Removing `ssh`, `--set-default-zone=drop`, moving the management interface, or `--panic-on` all cut the session. Change zones on other interfaces; keep `ssh` where you connect.
> - **Expecting a zone to apply everywhere.** A zone governs only traffic whose source or incoming interface is bound to it. An unassigned interface is in the *default* zone.
> - **Interface zone not persisting.** On an NM-managed host, set `connection.zone` on the connection, not just `firewall-cmd --change-interface`.
> - **Editing `nft` rules on a firewalld host.** firewalld rewrites `table inet firewalld` on every reload. Manage the firewall with `firewall-cmd` (Part 1).
> - **Reaching for `--direct`.** Almost always a rich rule does the job and stays visible in `--list-all`.

> *Runtime is immediate and volatile; permanent is on-disk and needs `--reload` to go live. `--reload` throws runtime away — `--runtime-to-permanent` first. `--set-default-zone` is the one flag that writes both.*

## Reference

- `man 1 firewall-cmd`, sections "RUNTIME AND PERMANENT CONFIGURATION" and "PANIC OPTIONS" — the authoritative split and the panic commands.
- `man 1 firewall-offline-cmd` — offline editing during rescue.
- `man 5 firewalld.conf` — `DefaultZone`, `FirewallBackend`, `LogDenied`.
- **firewalld.org, "firewall-cmd"** (`https://firewalld.org/documentation/utilities/firewall-cmd.html`) — the runtime/permanent model with examples.
