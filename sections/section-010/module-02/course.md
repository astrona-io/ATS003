# Managing Linux Hostnames

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-010/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-02/playground
> astrona destroy linux-hostnames-playground
> ```

A hostname is the name used to identify a Linux machine. It provides a human-readable identity, making the machine easier to recognize than using only its IP address.

For example, a hostname such as `prod-app-01` can indicate that the machine is the first application server in a production environment.

Hostnames are commonly used by:

- System administrators.
- Monitoring and logging systems.
- Configuration-management tools.
- Network services.
- Other machines on the network.

Setting a hostname does not automatically make the machine reachable by that name. A name-resolution mechanism, such as DNS or `/etc/hosts`, must map the hostname to an IP address.

## Learning objectives

After this module you can:

- Name the three hostname types `systemd` tracks — static, transient, pretty — and state what each is for.
- Read `hostnamectl status` and identify the static hostname, and explain when a separate `Transient hostname:` line appears.
- Set a persistent hostname with `sudo hostnamectl set-hostname --static` and verify it in `/etc/hostname`.
- Set a transient (runtime-only) hostname and a pretty (human-readable) hostname without changing the technical name.
- Explain why setting a hostname does not make the machine reachable by that name, and name the mechanisms that do.
- Predict which hostname values survive a reboot and which do not.

## Before you start

This module assumes you can open a shell on a Linux machine, run commands with `sudo`, and have seen a dotted IPv4 address like `192.168.1.50` before. It assumes a distribution that uses `systemd` — nearly every current one — because every command here is `hostnamectl`. No prior knowledge of DNS or `/etc/hosts` is needed; name resolution is only sketched, and has its own module.

The playground gives you a throwaway Linux VM that starts with a deliberate split: the static hostname `web-01` written on disk, and a *different* transient hostname `dhcp-guest-42` handed out at boot, so `hostnamectl status` shows both lines. No pretty hostname is set. Every command below is safe on this VM; the final checkpoint reboots it and drops your SSH session for about a minute.

## Key terms

| Term | Meaning in this chapter |
|---|---|
| **Hostname** | A name that identifies a machine. |
| **`systemd`** | The init system and service manager on most current Linux distributions; it provides `hostnamectl`. |
| **Static hostname** | The persistent technical name, stored on disk, restored on every boot. |
| **Transient hostname** | The name the running kernel currently uses. Set at runtime (sometimes by DHCP); not saved across a reboot on its own. |
| **Pretty hostname** | An optional free-form description meant for people, never used as a network name. |
| **`/etc/hostname`** | The file that holds the static hostname. |
| **`hostnamectl`** | The `systemd` tool for viewing and changing all three hostname types. |

## Hostname types

On Linux systems using `systemd`, a machine can have three types of hostnames:

1. Static hostname.
2. Transient hostname.
3. Pretty hostname.

A way to hold the three apart: the **static** hostname is the name written down (it survives a reboot and acts as the machine's official name); the **transient** hostname is the name the running kernel answers to right now (it can be handed out at boot, and is forgotten on reboot unless something sets it again); the **pretty** hostname is a label for humans that never travels over the network.

### Static hostname

The static hostname is the persistent technical name configured by the administrator.

It is normally stored in:

```text
/etc/hostname
```

Because it is persistent, the static hostname remains configured after the machine restarts.

Example:

```text
prod-app-01
```

A static hostname should normally contain:

- Lowercase letters from `a` to `z`.
- Numbers from `0` to `9`.
- Hyphens (`-`).

Avoid spaces and special characters in a static hostname.

Good examples include:

```text
prod-app-01
database-02
worker-node-03
```

### Transient hostname

The transient hostname is the hostname currently used by the running Linux kernel.

It can be assigned dynamically during startup or received from a network service such as DHCP. Because it is a runtime value, it may change while the machine is running and might not be preserved after a restart.

When a static hostname is configured, it normally takes priority: `systemd` sets the transient hostname to match the static one, and `hostnamectl status` then shows only a single hostname. A separate `Transient hostname:` line appears only when the two values differ.

### Pretty hostname

The pretty hostname is an optional, human-readable description of the machine.

Unlike the static hostname, it can contain:

- Spaces.
- Uppercase letters.
- Special characters.
- UTF-8 characters.

Example:

```text
Marketing Server - Primary
```

The pretty hostname is intended for people. It should not be used as a DNS name or as the machine's technical network identity.

A machine can therefore have both a technical static hostname and a more descriptive pretty hostname:

```text
Static hostname: prod-app-01
Pretty hostname: Marketing Server - Primary
```

## Viewing the current hostname

Use the `hostnamectl` command to inspect hostname information on a system running `systemd`:

```bash
hostnamectl status
```

On current `systemd` versions, running `hostnamectl` with no arguments prints the same information.

Example output:

```text
 Static hostname: prod-app-01
 Pretty hostname: Marketing Server - Primary
       Icon name: computer-vm
         Chassis: vm
      Machine ID: 0123456789abcdef0123456789abcdef
         Boot ID: abcdef0123456789abcdef0123456789
  Virtualization: kvm
Operating System: Ubuntu 24.04 LTS
          Kernel: Linux 6.8.0
    Architecture: x86-64
```

The exact output depends on the operating system and environment.

Important fields include:

- `Static hostname`: The persistent technical hostname.
- `Pretty hostname`: The optional human-readable description.
- `Chassis`: The type of machine, such as a server, desktop, or virtual machine.
- `Virtualization`: The detected virtualization technology.
- `Operating System`: The installed Linux distribution.
- `Kernel`: The currently running Linux kernel.
- `Architecture`: The machine's processor architecture.

The `hostname` command can also display the hostname currently used by the system:

```bash
hostname
```

To inspect the persistent hostname file directly, run:

```bash
cat /etc/hostname
```

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

## Setting a static hostname

Use `hostnamectl set-hostname` with the `--static` option to configure a persistent hostname:

```bash
sudo hostnamectl set-hostname prod-app-01 --static
```

The `--static` option makes it explicit that the persistent technical hostname should be changed. `sudo` is required because this writes a system file (`/etc/hostname`) and changes a system-wide setting.

The new hostname should be available immediately. A system restart is normally not required.

Display the configured static hostname:

```bash
hostnamectl hostname
```

(On older `systemd` versions this subcommand is `hostnamectl --static`.)

You can also inspect the persistent hostname file:

```bash
cat /etc/hostname
```

Expected value:

```text
prod-app-01
```

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
> Expect `hostnamectl hostname` and `/etc/hostname` to both read `prod-app-01`, and the `Transient hostname:` line to have **disappeared** from `hostnamectl status`. Setting the static hostname made `systemd` align the kernel's transient name with it, so there is no longer a second value to report. The change is live immediately — no restart. Your shell prompt keeps the old name until you start a new session.

## Setting a pretty hostname

Use the `--pretty` option to configure a human-readable description:

```bash
sudo hostnamectl set-hostname "Marketing Server - Primary" --pretty
```

Quotation marks are required because the description contains spaces.

The pretty hostname does not replace the static hostname. The machine now has two different names for different purposes:

```text
Static hostname: prod-app-01
Pretty hostname: Marketing Server - Primary
```

Display the pretty hostname:

```bash
hostnamectl hostname --pretty
```

Display all hostname information:

```bash
hostnamectl status
```

> [!TIP]
> **Try it — add a pretty hostname without touching the technical one**
>
> ```sh
> sudo hostnamectl set-hostname "Marketing Server - Primary" --pretty
> hostnamectl hostname --pretty
> hostnamectl hostname
> ```
>
> `hostnamectl hostname --pretty` returns the free-form description; `hostnamectl hostname` still returns the plain static name, unchanged. One machine, two names, two jobs — the pretty one for a person reading a screen, the static one for anything technical.

## Setting a transient hostname

The transient hostname is the name the running kernel uses right now. You rarely set it by hand — it is normally left to track the static hostname, or handed out by DHCP at boot — but `hostnamectl` can set it on its own with `--transient`:

```bash
sudo hostnamectl set-hostname build-scratch --transient
```

This changes only the runtime value. `/etc/hostname` is not touched, and the name is dropped on the next reboot. Because a configured static hostname normally overrides the transient one, the effect is only visible once you deliberately let the two values differ — which is exactly what `--transient` does.

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

A hostname identifies the machine, but it does not automatically provide network name resolution.

For another machine to connect to `prod-app-01` by name, the name must be mapped to an IP address using a mechanism such as:

- A DNS record.
- An entry in `/etc/hosts`.
- A local name-resolution service.

For example, an `/etc/hosts` entry might look like this:

```text
192.168.1.50 prod-app-01
```

Without such a mapping, the hostname can still identify the local machine, but other systems might not be able to resolve it to an IP address.

Local and network name resolution are covered in a separate module.

> [!TIP]
> **Try it — confirm which values survive a reboot**
>
> This restarts the VM and drops your SSH session for about a minute; reconnect with `astrona ssh linux-hostnames-playground`.
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
> The static hostname (and a pretty hostname, if you set one) are still there — they are stored on disk. A transient hostname set only with `--transient` would be gone. This is the practical difference between the persistent static name and the runtime transient one.
