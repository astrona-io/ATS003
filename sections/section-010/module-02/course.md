# Managing Linux Hostnames

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-010/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-02/playground
> astrona destroy linux-hostnames-playground
> ```

A **hostname** is the name that identifies a Linux machine. It gives the machine a human-readable identity, so people and tools can refer to `prod-app-01` instead of `192.168.1.50`. A well-chosen name also carries information: `prod-app-01` reads as "the first application server in production."

On a `systemd` system the picture is a little larger than one name. `systemd` tracks **three** hostname values at once — static, transient, and pretty — and this module is about seeing all three, changing each on its own, and knowing which ones survive a reboot.

One thing a hostname does *not* do: setting it does not make the machine reachable by that name. A separate name-resolution mechanism — DNS or `/etc/hosts` — has to map the name to an IP address. That is the next module; here the focus is the name itself.

## Learning objectives

After this module you can:

- Name the three hostname types `systemd` tracks — static, transient, pretty — and state what each is for.
- Read `hostnamectl status` and identify the static hostname, and explain when a separate `Transient hostname:` line appears.
- Set a persistent hostname with `sudo hostnamectl set-hostname --static` and verify it in `/etc/hostname`.
- Set a transient (runtime-only) hostname and a pretty (human-readable) hostname without changing the technical name.
- Explain why setting a hostname does not make the machine reachable by that name, and name the mechanisms that do.
- Predict which hostname values survive a reboot and which do not.

## Before you start

This module assumes you can open a shell, run commands with `sudo`, and have seen a dotted IPv4 address such as `192.168.1.50`. It assumes a distribution that uses `systemd` — nearly every current one — because every command here is `hostnamectl`. No knowledge of DNS or `/etc/hosts` is needed; name resolution is only sketched, and has its own module.

Open a shell on the playground VM with `astrona ssh astro-linux-hostnames-playground`. It starts with a deliberate split: the static hostname `web-01` written on disk, and a *different* transient hostname `dhcp-guest-42` set at boot, so `hostnamectl status` shows both lines. No pretty hostname is set. Every command below is safe on this VM; the final checkpoint reboots it and drops your SSH session for about a minute.

## Key terms

| Term | Meaning in this module |
|---|---|
| **Hostname** | A name that identifies a machine. |
| **`systemd`** | The init system and service manager on most current Linux distributions; it provides `hostnamectl`. |
| **Static hostname** | The persistent technical name, stored on disk in `/etc/hostname`, restored on every boot. |
| **Transient hostname** | The name the running kernel currently uses. Set at runtime (sometimes by DHCP); not saved across a reboot on its own. |
| **Pretty hostname** | An optional free-form description meant for people, never used as a network name. |
| **`hostnamectl`** | The `systemd` tool for viewing and changing all three hostname types. |

## The three hostname types

On a `systemd` system a machine has three hostname values, each with its own job:

- The **static** hostname is the name written down. It lives in `/etc/hostname`, survives a reboot, and acts as the machine's official technical name.
- The **transient** hostname is the name the running kernel answers to right now. It can be handed out at boot (often by DHCP) and is forgotten on reboot unless something sets it again.
- The **pretty** hostname is a label for humans — free-form text, never sent over the network.

When a static hostname is configured it normally wins: `systemd` sets the transient hostname to match the static one, and `hostnamectl status` then shows a single hostname line. A separate `Transient hostname:` line appears **only when the two values differ** — which is exactly the state the playground is seeded in.

### Naming rules

A static hostname should contain only:

- lowercase letters `a`–`z`;
- digits `0`–`9`;
- hyphens (`-`).

Avoid spaces and other special characters. Good examples: `prod-app-01`, `database-02`, `worker-node-03`.

The pretty hostname has no such restriction — spaces, uppercase, punctuation, and UTF-8 are all allowed, because it is only ever read by a person:

```text
Marketing Server - Primary
```

## `hostnamectl`: one tool for all three

`hostnamectl` — read it as *hostname control* — is the `systemd` tool for viewing and changing every hostname value. The pattern is small:

- `hostnamectl status` (or just `hostnamectl`) — show everything.
- `hostnamectl hostname` — print one value; add `--pretty` or `--transient` for those.
- `sudo hostnamectl set-hostname <name> [--static|--pretty|--transient]` — change one value. With no flag it changes the static hostname and pulls the transient one along with it.

`sudo` is needed for any `set-hostname` because it writes a system file and changes a system-wide setting. Reading needs no privilege.

`hostnamectl status` also prints machine facts that are not hostnames — `Chassis`, `Virtualization`, `Operating System`, `Kernel`, `Architecture` — handy for orienting yourself on an unfamiliar box. Exact values depend on the image.

> [!TIP]
> **Try it — see all three hostname types the playground starts with**
>
> ```sh
> hostnamectl status
> cat /etc/hostname
> ```
>
> Expect something like:
>
> ```text
>    Static hostname: web-01
> Transient hostname: dhcp-guest-42
>            Chassis: vm
>     Virtualization: kvm
>   Operating System: Ubuntu 24.04 LTS
> ```
>
> The playground seeded the static hostname as `web-01` and a *different* transient hostname `dhcp-guest-42`, so both lines show. There is no `Pretty hostname:` line because none is set. `cat /etc/hostname` prints `web-01` only — the file holds the static value. Field values vary by image.

## Setting the static hostname

Use `set-hostname` with `--static` for the persistent technical name:

```bash
sudo hostnamectl set-hostname prod-app-01 --static
```

The change takes effect immediately — no restart. It writes `/etc/hostname`, so it also survives a reboot. Because a configured static hostname normally overrides the transient one, `systemd` realigns the kernel's transient name to match, and the separate `Transient hostname:` line disappears.

Check the result with `hostnamectl hostname` (on older `systemd`, `hostnamectl --static`) or by reading `/etc/hostname` directly.

> [!TIP]
> **Try it — set the static hostname and watch the transient one fall in line**
>
> ```sh
> sudo hostnamectl set-hostname prod-app-01 --static
> hostnamectl hostname
> cat /etc/hostname
> hostnamectl status
> ```
>
> Expect `hostnamectl hostname` and `/etc/hostname` to both read `prod-app-01`, and the `Transient hostname:` line to have **disappeared** from `hostnamectl status`. Setting the static hostname made `systemd` align the kernel's transient name with it, so there is no longer a second value to report. The change is live immediately — no restart. Your shell prompt keeps the old name until you open a new session.

## Setting the pretty hostname

Use `--pretty` for the human-readable description. Quote it if it contains spaces:

```bash
sudo hostnamectl set-hostname "Marketing Server - Primary" --pretty
```

The pretty hostname does not replace the static one. The machine now carries two names for two purposes — a technical `prod-app-01` for anything that talks to the network, and `Marketing Server - Primary` for a person reading a screen.

> [!TIP]
> **Try it — add a pretty hostname without touching the technical one**
>
> ```sh
> sudo hostnamectl set-hostname "Marketing Server - Primary" --pretty
> hostnamectl hostname --pretty
> hostnamectl hostname
> ```
>
> `hostnamectl hostname --pretty` returns the free-form description; `hostnamectl hostname` still returns the plain static name, unchanged. One machine, two names, two jobs.

## Setting the transient hostname

The transient hostname is the name the running kernel uses right now. You rarely set it by hand — it is normally left to track the static hostname, or handed out by DHCP at boot — but `--transient` sets it on its own:

```bash
sudo hostnamectl set-hostname build-scratch --transient
```

This changes only the runtime value. `/etc/hostname` is untouched, and the name is dropped on the next reboot. Because a configured static hostname normally overrides the transient one, the effect is visible only once you deliberately let the two values differ — which is what `--transient` does.

> [!TIP]
> **Try it — set a transient-only name and watch the split reappear**
>
> Run this after the static checkpoint above, where setting `--static` had collapsed the two names into one:
>
> ```sh
> sudo hostnamectl set-hostname build-scratch --transient
> hostnamectl status
> cat /etc/hostname
> ```
>
> `hostnamectl status` now shows a `Transient hostname: build-scratch` line again, while `cat /etc/hostname` still reads the static value (`prod-app-01` if you followed the earlier checkpoint). You changed the name the kernel answers to without touching the persistent one — the reverse of the static checkpoint, where setting the static name pulled the transient one back into line.

## Hostnames and name resolution

A hostname identifies the machine; it does not provide network name resolution. For another machine to connect to `prod-app-01` by name, that name has to be mapped to an IP address by one of:

- a DNS record;
- an entry in `/etc/hosts`, for example `192.168.1.50 prod-app-01`;
- a local name-resolution service.

Without such a mapping the hostname still identifies the local machine, but other systems cannot resolve it. Local and network name resolution are the next module.

The static and pretty values are on disk, so they come back after a reboot. A transient hostname set only with `--transient` does not.

> [!TIP]
> **Try it — confirm which values survive a reboot**
>
> This restarts the VM and drops your SSH session for about a minute; reconnect with `astrona ssh astro-linux-hostnames-playground`.
>
> ```sh
> sudo reboot
> ```
>
> After reconnecting:
>
> ```sh
> hostnamectl status
> cat /etc/hostname
> ```
>
> The static hostname (and a pretty hostname, if you set one) are still there — they are stored on disk. A transient hostname set only with `--transient` is gone. This is the practical difference between the persistent static name and the runtime transient one.

> [!WARNING]
> **Common pitfalls**
>
> - **Expecting the name alone to make the machine reachable.** `hostnamectl set-hostname` changes identity, not resolution. Until the name is in DNS or `/etc/hosts`, other machines cannot connect to it by name — and even `sudo` on the machine itself may print `unable to resolve host <name>` until a local entry exists.
> - **Waiting for the shell prompt to update.** The change is live immediately, but your current session captured the old name at login. Open a new shell to see the new prompt; it is not a sign the change failed.
> - **Using the old `hostname <name>` command for a permanent change.** That sets only the transient value and is lost on reboot. Use `hostnamectl set-hostname … --static` (which writes `/etc/hostname`) for a change that persists.
> - **Treating the pretty hostname as a network name.** It can contain spaces and capitals precisely because nothing technical ever reads it. Never use it as a DNS name or in configuration that expects a hostname.
> - **Expecting a `Transient hostname:` line when the values match.** After a `--static` change the transient name is realigned, so `hostnamectl status` shows one hostname line. The second line is a sign the two values differ, not a sign something is wrong.
