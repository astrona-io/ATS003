# Pretty Names, Transient Names And Reboots

Astronaut, your ship now has a registered name that lasts. A `systemd` machine keeps two more hostname values next to it: the pretty hostname for people, and the transient hostname the kernel uses right now.

This part shows you how to set each of them on its own, why no hostname makes a machine reachable, and which values are still there after a reboot.

## Setting the pretty hostname

The pretty hostname is the decorated name painted on the hull for visitors: a free-form description for people. Use `--pretty` to set it, and put quotes around it if it contains spaces:

<!-- astrona:playground:renew -->

```bash
sudo hostnamectl set-hostname "Marketing Server - Primary" --pretty
```

### Two names, two jobs

The pretty hostname does not replace the static one. The machine now carries two names for two purposes: a technical `prod-app-01` for anything that talks to the network, and `Marketing Server - Primary` for a person reading a screen.

`hostnamectl` stores the pretty hostname on disk, next to the static one, so it also survives a reboot.

### Add a pretty name without touching the technical one

Set the pretty hostname, then read both names back:

```sh
sudo hostnamectl set-hostname "Marketing Server - Primary" --pretty
hostnamectl hostname --pretty
hostnamectl hostname
```

`hostnamectl hostname --pretty` returns the free-form description. `hostnamectl hostname` still returns the plain static name, unchanged. One machine, two names, two jobs.

## Setting the transient hostname

The transient hostname is the name the running kernel uses right now. You rarely set it by hand. It normally follows the static hostname, or DHCP hands it out at boot. But `--transient` sets it on its own:

```bash
sudo hostnamectl set-hostname build-scratch --transient
```

### What changes and what does not

This changes only the runtime value. `/etc/hostname` stays untouched, and the kernel drops the name at the next reboot.

Because a set static hostname normally overrides the transient one, you only see the effect when you make the two values differ on purpose. That is exactly what `--transient` does.

### Set a transient-only name and watch the split come back

Run this after you have set the static hostname to `prod-app-01`, which made the two names one:

```sh
sudo hostnamectl set-hostname build-scratch --transient
hostnamectl status
cat /etc/hostname
```

`hostnamectl status` now shows a `Transient hostname: build-scratch` line again, while `cat /etc/hostname` still reads the static value (`prod-app-01` if you set it earlier). You changed the name the kernel answers to without touching the persistent one. It is the reverse of a `--static` change, which pulls the transient name back into line.

## Hostnames and name resolution

A hostname identifies the machine. It does not make the machine reachable by that name. This catches many people out, because the error appears on other machines, or in `sudo`, and not where you set the name.

### What makes a name reachable

For another machine to connect to `prod-app-01` by name, something has to map that name to an IP address (the ship's call sign). That is one of:

- a DNS record, in the galaxy-wide directory of call signs;
- a line in `/etc/hosts`, the ship's pocket address book, for example `192.168.1.50 prod-app-01`;
- a local name resolution service.

Without such a mapping, the hostname still identifies the local machine, but other systems cannot look it up.

### What survives a reboot

The static and pretty values are stored on disk, so they come back after a reboot. A transient hostname set only with `--transient` does not.

This step restarts the machine and drops your SSH session for about a minute. Reconnect with `astrona ssh linux-hostnames-playground`.

```sh
sudo reboot
```

After you reconnect, look at the names again:

```sh
hostnamectl status
cat /etc/hostname
```

The static hostname, and the pretty hostname if you set one, are still there, because they are stored on disk. A transient hostname set only with `--transient` is gone. That is the practical difference between the persistent static name and the runtime transient one.

> [!TIP]
> After any hostname change, open a new shell or check with `hostnamectl status` before you trust your prompt. The prompt shows the name from when you logged in.

## Common pitfalls

> [!WARNING]
> - **Expecting the name alone to make the machine reachable.** `hostnamectl set-hostname` changes identity, not resolution. Until the name is in DNS or `/etc/hosts`, other machines cannot connect to it by name, and even `sudo` on the machine itself may print `unable to resolve host <name>` until a local entry exists.
> - **Treating the pretty hostname as a network name.** It can contain spaces and capitals because nothing technical ever reads it. Never use it as a DNS name or in configuration that expects a hostname.
> - **Expecting a `--transient` name to survive a reboot.** It lives only in the running kernel. Use `--static` for a name that lasts.

## Your mission: Static Hostname Management Lab

You can now set the static, pretty and transient hostnames, and you know a name alone is not enough for the machine to resolve itself. The mission asks you to rename a freshly built machine, give it a pretty name, and fix the `127.0.1.1` line in `/etc/hosts` so it matches the new name.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop linux-hostnames-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-02/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-012
astrona start linux-hostnames-playground
```
