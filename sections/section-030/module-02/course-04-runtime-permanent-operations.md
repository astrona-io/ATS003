# Runtime, Permanent And Operations

Astronaut, every `firewall-cmd` change lands in one of two places. Mixing them up is the most common firewalld mistake: a change that "did nothing" (saved, but never reloaded) or a change that "disappeared" (live only, then reloaded away).

This part nails down that split, the commands that bridge it, what makes an interface binding survive a reboot, and the ways people lock themselves out.

## Runtime and permanent

firewalld keeps two copies of its configuration: the shield setting in force now, and the setting saved for the next start. This section shows how they differ.

### The two copies side by side

| | **Runtime** (default) | **Permanent** (`--permanent`) |
|---|---|---|
| Where it lands | the live daemon state and kernel ruleset | the XML files under `/etc/firewalld/` |
| Takes effect | at once | **not until `firewall-cmd --reload`** |
| Survives `--reload` | **no**: a reload throws runtime away and reads permanent again | yes |
| Survives a reboot or `systemctl restart firewalld` | no | yes |
| Shown by `--list-all`, `--list-services` | yes (these read **runtime**) | only after a reload |

### Two traps

Two results of this split catch people all the time:

- `--permanent` **without** `--reload` looks like nothing happened. `--list-services` reads runtime, and runtime has not changed yet.
- A plain runtime change looks permanent, until the next `--reload`, service restart or reboot silently wipes it.

## The bridging commands

Some commands move configuration between the two copies, and one is a special case. These are the ones to know:

| Command | Effect |
|---|---|
| `firewall-cmd --reload` | throw runtime away, apply permanent again, **keep** the connection tracking state |
| `firewall-cmd --complete-reload` | as above, but also drop the connection tracking state; breaks live connections, so use it only when stuck |
| `firewall-cmd --runtime-to-permanent` | copy the **whole** current runtime set to disk in one step: the "I tested it live, now save it" button |
| `firewall-cmd --set-default-zone=<z>` | **exception:** changes runtime *and* permanent at once, no `--reload` needed |
| `firewall-cmd --check-config` | check the permanent XML files before a reload trips over them |

`--set-default-zone` changing both at once is a real special case worth remembering. Most other change options do not.

## See the split on your playground

Now watch both copies change on your playground: first a permanent change and a reload, then a runtime change saved to disk.

### Add a service permanently and watch the reload

<!-- astrona:playground:renew -->

```sh
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --zone=public --list-services
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-services
```

`http` is **missing** from the first listing and **present** after the reload:

```text
dhcpv6-client ssh
dhcpv6-client ssh http
```

`--list-services` reads the runtime configuration, and `--permanent` did not touch that. Only `--reload` applied it. The same reload also removes any runtime-only port you opened earlier: check with `sudo firewall-cmd --zone=public --list-ports`, and it is gone.

### Save a tested runtime change

```sh
sudo firewall-cmd --zone=public --add-port=9100/tcp     # runtime only
sudo firewall-cmd --runtime-to-permanent                # commit everything runtime to disk
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-ports            # 9100/tcp is still there
```

Without the `--runtime-to-permanent`, that `--reload` would have removed `9100/tcp`.

> [!TIP]
> After any firewalld change, run the same list command twice: once plain and once with `--permanent`. If the two answers differ, you know at once which copy still needs work.

## What makes an interface binding last

An interface's zone can be recorded in three places, and *which one* decides whether it survives a reboot.

### Three places for one binding

| Managed by | Where the binding lives | Survives a reboot? |
|---|---|---|
| **NetworkManager** | the connection profile's `connection.zone` key | yes: NetworkManager applies it again when it brings the link up |
| **firewalld directly** (`--permanent --zone=X --add-interface=dev`) | `/etc/firewalld/zones/X.xml` | yes, but only if *something else* also brings the interface up |
| **runtime only** (`--change-interface` with no `--permanent`) | daemon memory | **no** |

NetworkManager is the service that manages the network antennas on many hosts. On a modern host it manages, the practical rule is: set the zone on the *connection*, for example `nmcli connection modify <name> connection.zone internal`. A `firewall-cmd --change-interface` on top of that can be undone the next time NetworkManager brings the link up again.

## Locking yourself out

Several firewalld commands cut your link to mission control in one step. Know them before you type them on a remote machine.

### The scenarios

Each of these cuts an SSH (Secure Shell, the sealed communications channel between ships) session on the management interface:

- **Removing `ssh` from the zone** that handles your management interface (`--remove-service=ssh`).
- **`--set-default-zone=drop`** (or `block`) while your interface relies on the default zone.
- **`--change-interface`** moving your management interface into a zone without `ssh`.
- **A source binding** that puts your own address into `drop` or `block`.
- **`--panic-on`**, which drops *all* traffic in and out at once, with no exceptions. `--panic-off` restores it and `--query-panic` checks it. There is no timer.

### Getting back in

On this throwaway playground, recovery is the serial console (`firewall-cmd --panic-off`, `firewall-cmd --reload`, or `systemctl restart firewalld` to drop runtime-only changes), or destroying and starting the playground again. On a real remote host, test firewall changes with a planned `--reload` or an "undo in N minutes" `at` job in place.

## Other operational commands

A few more commands you will meet on real hosts:

- **`firewall-cmd --direct ...`** is an escape hatch that injects raw `iptables` or `nft` rules into firewalld's chains. Avoid it: it bypasses the zone model, and the rules do not show in `--list-all`. Rich rules cover almost every case people reach for `--direct` for.
- **`firewall-cmd --set-log-denied=all`** (then `--reload`) logs rejected and dropped packets to the kernel log; `--get-log-denied` shows the current setting. It is off by default.
- **`firewall-offline-cmd`** has the same syntax as `firewall-cmd --permanent`, but edits `/etc/firewalld/` with the daemon **stopped**. Use it in rescue mode and when building images.
- **`systemctl restart firewalld`** throws away all runtime changes, the same as a reboot does for the firewall. `--reload` is almost always what you want instead.

## Common pitfalls

> [!WARNING]
> - **`--permanent` without `--reload`.** The change is on disk but not live. `--list-all` and `--list-services` read runtime, so the change seems to be missing.
> - **A runtime change treated as saved.** Anything without `--permanent` is gone after `--reload`, `systemctl restart firewalld` or a reboot. Use `--runtime-to-permanent` to keep the current set.
> - **Expecting `--reload` to be harmless.** It *throws away* every runtime-only change. Save first.
> - **Locking yourself out.** Removing `ssh`, `--set-default-zone=drop`, moving the management interface or `--panic-on` all cut the session. Change zones on other interfaces, and keep `ssh` where you connect.
> - **An interface zone that does not last.** On a host managed by NetworkManager, set `connection.zone` on the connection, not only `firewall-cmd --change-interface`.
> - **Reaching for `--direct`.** A rich rule almost always does the job and stays visible in `--list-all`.

> *Runtime is immediate and lost on reload; permanent is on disk and needs `--reload` to go live. `--reload` throws runtime away, so run `--runtime-to-permanent` first. `--set-default-zone` is the one option that writes both.*

## Your mission: firewalld Zones and Services Lab

You can now open services and ports in a zone and make a change both live now and saved for later. Now prove it in a graded mission: open one service and one port in the `public` zone, in both the runtime and the permanent configuration.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop firewalld-zones-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-030/module-02/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-032
astrona start firewalld-zones-playground
```
