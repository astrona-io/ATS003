# Overview: PLAYGROUND — DNS Client Resolution (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh dns-resolver-playground`.
- `dns0`: a dummy interface with `10.55.0.53/24`.
- `named` (BIND) on `10.55.0.53` with the zone `lab.example`:
  `www` = `203.0.113.10`, `db` = `203.0.113.20`, `app` = `203.0.113.30`.
- `systemd-resolved` at the Ubuntu defaults. It is not told about `10.55.0.53`.

## Things to try

- **Who is asked.** `grep '^hosts:' /etc/nsswitch.conf`, `getent hosts db.lab.example`,
  `dig +short @10.55.0.53 db.lab.example`.
- **The stub.** `ls -l /etc/resolv.conf`, `resolvectl status`, `resolvectl query www.lab.example`.
- **Teach the clerk.** Write `/etc/systemd/resolved.conf.d/10-lab.conf` with
  `[Resolve]`, `DNS=10.55.0.53`, `Domains=lab.example`, restart
  `systemd-resolved`, then `getent hosts db`.
- **The pocket book.** Pin a name in `/etc/hosts` and compare `getent` with `dig`.
- **The cache.** `sudo resolvectl flush-caches`.

## What this sandbox does not set up

- **Internet DNS.** Only `lab.example` is served here.
- **Anything to grade.**

## When you're done

```sh
astrona destroy dns-resolver-playground
```

(`astrona destroy` takes the environment name, not the config path.)
