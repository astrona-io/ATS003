# Overview: PLAYGROUND — OpenSSH Client (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh ssh-client-playground`.
- Two users: `cadet` (`cadetpass`, the visitor) and `pilot` (`pilotpass`, the
  remote account). Do the client work with `sudo -iu cadet`.
- `sshd-station.service` on `127.0.0.1:2222` and `sshd-relay.service` on
  `127.0.0.1:2223`. Both allow only the user `pilot`.
- `station-data.service`: a web page on `127.0.0.1:8081`.

## Things to try

- **Make a key.** `ssh-keygen -t ed25519`, then list `~/.ssh`.
- **Install it.** `ssh-copy-id -p 2222 pilot@localhost`, then log in with no password.
- **Host key check.** `ssh-keygen -F '[localhost]:2222'`, then
  `ssh-keygen -R '[localhost]:2222'` and connect again.
- **Config file.** Write a `Host station` block in `~/.ssh/config` (`chmod 600`),
  then `ssh -G station`.
- **Jump host.** `ssh -J pilot@localhost:2223 -p 2222 pilot@localhost hostname`.
- **Tunnels.** `-L 9090:127.0.0.1:8081`, `-R`, `-D 1080`; prove them with `ss -tlnp`.

## What this sandbox does not set up

- **A second machine.** Everything runs on one ship, so every address is `localhost`.
- **Anything to grade.**

## When you're done

```sh
astrona destroy ssh-client-playground
```

(`astrona destroy` takes the environment name, not the config path.)
