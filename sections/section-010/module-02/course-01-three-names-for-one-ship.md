# Three Names For One Ship

Astronaut, a ship has a registered name in the fleet records, a name it answers to on the radio right now, and sometimes a decorated name painted on the hull for visitors. A Linux machine that runs `systemd` has the same three: the static, transient and pretty hostnames.

This part shows you what each name is for, the one tool that reads and changes all three, and how to set the name that lasts.

## Words you will meet

| Term | Meaning |
|---|---|
| **Hostname** | A name that identifies a machine. |
| **`systemd`** | The init system and service manager on most current Linux distributions; it provides `hostnamectl`. |
| **Static hostname** | The persistent technical name, stored on disk in `/etc/hostname` and restored at every boot. The ship's registered name. |
| **Transient hostname** | The name the running kernel uses right now. It is set at runtime (sometimes by DHCP) and is not saved across a reboot on its own. The name the ship answers to right now. |
| **Pretty hostname** | An optional free-form description meant for people, never used as a network name. The decorated name painted for visitors. |
| **`hostnamectl`** | The `systemd` tool for viewing and changing all three hostname types. |

## The three hostname types

On a `systemd` system a machine has three hostname values, and each one has its own job. Knowing which is which tells you which one to set, and which one survives a reboot.

### What each name does

- The **static** hostname is the name written down. It lives in `/etc/hostname`, survives a reboot, and acts as the machine's official technical name.
- The **transient** hostname is the name the running kernel answers to right now. It can be handed out at boot (often by DHCP, the harbour master that hands out call signs) and is forgotten at reboot unless something sets it again.
- The **pretty** hostname is a label for people: free-form text, never sent over the network.

When a static hostname is set, it normally wins. `systemd` sets the transient hostname to match the static one, and `hostnamectl status` then shows a single hostname line. A separate `Transient hostname:` line appears **only when the two values differ**. Your playground starts in exactly that state.

### Naming rules

A static hostname should contain only:

- lowercase letters `a` to `z`;
- digits `0` to `9`;
- hyphens (`-`).

Avoid spaces and other special characters. Good examples are `prod-app-01`, `database-02` and `worker-node-03`.

The pretty hostname has no such limits. Spaces, capital letters, punctuation and UTF-8 characters are all allowed, because only a person ever reads it:

```text
Marketing Server - Primary
```

## `hostnamectl`: one tool for all three

`hostnamectl` (read it as *hostname control*) is the `systemd` tool for viewing and changing every hostname value. Its pattern is small, and you use the same few forms in every hostname task.

### The commands

- `hostnamectl status` (or just `hostnamectl`) shows everything.
- `hostnamectl hostname` prints one value; add `--pretty` or `--transient` for those.
- `sudo hostnamectl set-hostname <name> [--static|--pretty|--transient]` changes one value. With no flag it changes the static hostname and pulls the transient one along with it.

Any `set-hostname` needs `sudo` (the captain's authority), because it writes a system file and changes a setting for the whole machine. Reading needs no special rights.

`hostnamectl status` also prints facts about the machine that are not hostnames: `Chassis`, `Virtualization`, `Operating System`, `Kernel` and `Architecture`. They help you find your way on an unfamiliar machine. The exact values depend on the image.

### See the three names your playground starts with

<!-- astrona:playground:renew -->

Show every hostname value, then the file that holds the static one:

```sh
hostnamectl status
cat /etc/hostname
```

The output looked like this when the module was written:

```text
   Static hostname: web-01
Transient hostname: dhcp-guest-42
           Chassis: vm
    Virtualization: kvm
  Operating System: Ubuntu 24.04 LTS
```

The playground set the static hostname to `web-01` and a *different* transient hostname, `dhcp-guest-42`, so both lines show. There is no `Pretty hostname:` line because none is set. `cat /etc/hostname` prints only `web-01`: the file holds the static value. Field values vary with the image.

## Setting the static hostname

The static hostname is the one you set in almost every real task, because it is the one that lasts. Use `set-hostname` with `--static`:

```bash
sudo hostnamectl set-hostname prod-app-01 --static
```

### What happens when you set it

The change takes effect at once, with no restart. `hostnamectl` writes `/etc/hostname`, so the name also survives a reboot. Because a set static hostname normally overrides the transient one, `systemd` brings the kernel's transient name back in line, and the separate `Transient hostname:` line disappears.

Check the result with `hostnamectl hostname` (on older `systemd` versions, `hostnamectl --static`) or by reading `/etc/hostname` directly.

### Set it and watch the transient name fall in line

Set the static hostname, then look at it three ways:

```sh
sudo hostnamectl set-hostname prod-app-01 --static
hostnamectl hostname
cat /etc/hostname
hostnamectl status
```

`hostnamectl hostname` and `/etc/hostname` both read `prod-app-01`, and the `Transient hostname:` line has **disappeared** from `hostnamectl status`. Setting the static hostname made `systemd` align the kernel's transient name with it, so there is no second value left to report. Your shell prompt keeps the old name until you open a new session.

## Common pitfalls

> [!WARNING]
> - **Waiting for the shell prompt to change.** The change is live at once, but your current session read the old name when you logged in. Open a new shell to see the new prompt; it is not a sign that the change failed.
> - **Using the old `hostname <name>` command for a permanent change.** It sets only the transient value, which is lost at reboot. Use `hostnamectl set-hostname … --static`, which writes `/etc/hostname`.
> - **Expecting a `Transient hostname:` line when the values match.** After a `--static` change the transient name is aligned, so `hostnamectl status` shows one hostname line. A second line means the two values differ, not that something is wrong.
