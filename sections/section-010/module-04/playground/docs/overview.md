# Overview: PLAYGROUND — Local Hostname Resolution (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server host. Reach it with
  `astrona ssh hostname-resolution-playground`.
- The static hostname is set to **`prod-app-01`**.
- `/etc/hosts` is seeded with:
  - `127.0.0.1 localhost` and `::1 localhost ...` — the standard entries;
  - `127.0.1.1 prod-app-01 app-server` — the Debian-style loopback mapping for
    this host, with `app-server` as an alias;
  - `192.168.50.10 db-primary db` — an example name pointing at an
    interface-style address. Nothing is actually listening at `192.168.50.10`;
    it is there so a name can resolve to a non-loopback address.
- `/etc/nsswitch.conf` is whatever the image ships (typically
  `hosts: files ... dns`).
- Tools: `getent` (from libc), `hostnamectl`, `grep`, `iputils-ping`.

## What you can see fully

- **Read the static table:** `cat /etc/hosts`.
- **Resolve through NSS, not by reading the file:** `getent hosts prod-app-01`,
  `getent hosts db-primary`, `getent hosts localhost`. Compare with
  `getent ahostsv4 prod-app-01` and `getent ahostsv6 localhost`.
- **See the lookup order:** `grep '^hosts:' /etc/nsswitch.conf`. Sources are
  consulted left to right, so `files` before `dns` means `/etc/hosts` wins.
- **Add an entry and watch it take effect immediately** — no service restart:
  ```sh
  echo '10.0.0.9 test-node' | sudo tee -a /etc/hosts
  getent hosts test-node
  ```
  Undo it by editing `/etc/hosts` back (`sudo nano /etc/hosts`).
- **`getent` vs `ping` for testing resolution:** `getent hosts db-primary`
  returns the mapping instantly; `ping -c1 db-primary` resolves the name but
  then fails on reachability, because nothing answers at `192.168.50.10`. That
  is the distinction the module draws — name resolution is not connectivity.
- **Change the hostname** with `sudo hostnamectl set-hostname <name>` and see
  `hostnamectl` and `getent hosts <name>` react. If you pick a name with no
  `/etc/hosts` entry, some tools print
  `unable to resolve host <name>: Name or service not known`.

## What this sandbox cannot show

- **Real DNS.** There is no DNS server on the isolated network, so
  `getent hosts <public-name>` and any `dns` step in `nsswitch` return nothing.
  The `files` source is the whole story here.
- **mDNS / `.local` names.** No `avahi` / `systemd-resolved` mDNS responder and
  no peers, so `host.local` lookups do not resolve.
- **Network-wide effect.** An `/etc/hosts` entry only changes resolution on this
  one VM. There is no second machine to demonstrate that against.

## When you're done

```sh
astrona destroy hostname-resolution-playground
```

(`astrona destroy` takes the environment name, not the config path.)
