# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the three names a `systemd` machine carries, and which of them last.

**From [Three Names For One Ship](./course-01-three-names-for-one-ship.md):**

- The **static** hostname lives in `/etc/hostname` and survives a reboot. The **transient** hostname is what the running kernel uses now. The **pretty** hostname is a free-form label for people.
- A static hostname uses only lowercase letters, digits and hyphens. The pretty hostname may contain anything.
- `hostnamectl status` shows every value. A separate `Transient hostname:` line appears only when the transient and static values differ.
- `sudo hostnamectl set-hostname <name> --static` writes `/etc/hostname`, takes effect at once, and pulls the transient name into line.

**From [Pretty Names, Transient Names And Reboots](./course-02-pretty-transient-and-reboots.md):**

- `sudo hostnamectl set-hostname "<text>" --pretty` sets the pretty name without touching the static one.
- `sudo hostnamectl set-hostname <name> --transient` changes only the runtime name. `/etc/hostname` stays the same.
- A hostname does not make the machine reachable. A DNS record, an `/etc/hosts` line or a local name service must map the name to an address.
- After a reboot the static and pretty names are still there; a transient-only name is gone.

## Your missions

You proved the skills of this module in a graded mission:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Static Hostname Management Lab](./labs/lab-01/README.md) | Pretty Names, Transient Names And Reboots | rename a machine for good, set its pretty name, and fix its `127.0.1.1` line |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. <code>hostnamectl status</code> shows a <code>Static hostname:</code> line and a separate <code>Transient hostname:</code> line. What does that tell you?</summary>

The two values differ. When they match, `hostnamectl status` shows only one hostname line.
</details>

<details>
<summary>2. You ran <code>sudo hostname web-02</code>. Will the name survive a reboot?</summary>

No. The plain `hostname` command sets only the transient value. Use `sudo hostnamectl set-hostname web-02` (or with `--static`) so the name is written to `/etc/hostname`.
</details>

<details>
<summary>3. Is <code>Marketing Server - Primary</code> a valid static hostname?</summary>

No. A static hostname should use only lowercase letters, digits and hyphens. That text is fine as a pretty hostname.
</details>

<details>
<summary>4. You renamed the machine, and now <code>sudo</code> prints <code>unable to resolve host</code>. Why?</summary>

The new name has no mapping to an address. Setting a hostname does not add one. Add the name to `/etc/hosts` (or DNS) so it resolves.
</details>

<details>
<summary>5. You set the hostname, but your shell prompt still shows the old one. Did it fail?</summary>

No. The change is live at once, but your session read the name when you logged in. Open a new shell, or check with `hostnamectl status`.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy linux-hostnames-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-012
```

Then run `astrona list` again and check that neither name is listed any more.

You can start the playground again at any time with the `astrona run` command for its folder, `sections/section-010/module-02/playground`. It always starts clean, so nothing you broke carries over.
