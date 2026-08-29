# Overview: PLAYGROUND — Managing Linux Hostnames (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server host with `systemd`. Reach it
  with `astrona ssh linux-hostnames-playground`.
- The three hostname types are seeded to three different values so
  `hostnamectl status` shows all of them:
  - **static** = `web-01` — the persistent technical name, in `/etc/hostname`;
  - **transient** = `dhcp-guest-42` — the kernel's runtime name, set here on
    purpose so it differs from the static one (on a real host this would come
    from DHCP or boot config);
  - **pretty** = *unset* — left empty for you to set.
- Tools: `hostnamectl`, `hostname`, `hostnamectl` completion — all from the base
  system.

## What you can see fully

- **All three names at once:** `hostnamectl status`. Note the separate
  `Static hostname:` and `Transient hostname:` lines — they show because the two
  values differ. Also `Chassis`, `Virtualization`, `Operating System`,
  `Kernel`, `Architecture`.
- **Just one value:** `hostnamectl hostname`, `hostnamectl hostname --pretty`,
  `hostnamectl hostname --transient`, and the plain `hostname` command.
- **The persistent file:** `cat /etc/hostname` — holds `web-01`, the static
  value only.
- **Set the static hostname** and watch the file and the live name follow:
  ```sh
  sudo hostnamectl set-hostname prod-app-01 --static
  hostnamectl hostname
  cat /etc/hostname
  ```
  Takes effect immediately; no restart. Persists across a reboot.
- **Set a pretty hostname** with spaces and capitals:
  ```sh
  sudo hostnamectl set-hostname "Marketing Server - Primary" --pretty
  hostnamectl status
  ```
  The static hostname is unchanged — a machine carries both.
- **Watch the static hostname override the transient one:** after
  `sudo hostnamectl set-hostname prod-app-01 --static`, the
  `Transient hostname:` line disappears from `hostnamectl status`, because the
  kernel name is now aligned with the static value.
- **Reboot and re-check** with `sudo reboot` (drops your SSH session for a
  minute; reconnect with `astrona ssh linux-hostnames-playground`). Static and
  pretty values survive; a transient value set with `--transient` does not.

## What this sandbox cannot show

- **A DHCP-assigned transient hostname.** There is no DHCP server on the
  network, so the transient value here was seeded by `bootstrap/prepare.sh`
  rather than learned from DHCP. The behaviour it illustrates is real; the
  source is faked.
- **Name resolution.** Setting a hostname does not make the machine reachable by
  that name. Mapping a name to an address (`/etc/hosts`, DNS) is a separate
  topic covered in its own module.
- **Network-wide effect.** These names are local to this one VM. There is no
  second machine here to resolve them from.

## When you're done

```sh
astrona destroy linux-hostnames-playground
```

(`astrona destroy` takes the environment name, not the config path.)
