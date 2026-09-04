# Overview: PLAYGROUND — firewalld Zones and Services (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server host. Reach it with
  `astrona ssh firewalld-zones-playground`.
- **firewalld running at its stock defaults**: default zone `public`, the `ssh`
  service allowed, nothing custom added. `firewall-cmd --state` returns
  `running`.
- `firewall-cmd`, plus `curl` and `python3` for generating and serving test
  traffic.
- Two local IPv4 addresses: the **management interface** that carries your SSH
  session, and **`192.168.90.10/24`** on a local dummy interface, used for
  interface-to-zone experiments. Find the kernel names with
  `ip -brief -4 addr show`.
- Password-less `sudo`. (firewalld's backend on Ubuntu 24.04 is nftables — see
  the previous module.)

## Things to try

Start a throwaway web server so a port has something behind it:

```sh
python3 -m http.server 8080
```

- **Read the current state.** `sudo firewall-cmd --get-default-zone`,
  `sudo firewall-cmd --get-active-zones`, `sudo firewall-cmd --list-all`.
- **List what a zone allows.** `sudo firewall-cmd --zone=public --list-services`
  and `--list-ports`. Compare with `--zone=trusted` and `--zone=drop`.
- **Open a service at runtime, then persistently.**
  `sudo firewall-cmd --zone=public --add-service=http` changes the live ruleset
  only; add `--permanent` and `--reload` to make it stick. `--runtime-to-permanent`
  copies the whole live config across.
- **Open a port or a range.**
  `sudo firewall-cmd --zone=public --add-port=8000-8010/tcp`. Probe 8080 with
  `curl` before and after opening `8080/tcp`.
- **Move the extra interface between zones.**
  `sudo firewall-cmd --zone=internal --change-interface=<dev>` for the
  `192.168.90.10` NIC, then `--get-active-zones` to see it move. Never do this
  to the management interface.
- **See the generated nftables rules.** `sudo nft list ruleset` — everything
  firewalld does lands there as `table inet firewalld`.
- **`--permanent` vs runtime.** Add a service with `--permanent` only, run
  `--list-services` (still absent — that reads runtime), then `--reload` and
  list again.

## What this sandbox does not set up

- **A second real host.** Zone behaviour is explored with the VM's own two
  interfaces and `curl`, not traffic arriving from another machine.
- **Rich services / ICMP-block / rich rules beyond the basics.** All available,
  none pre-configured.
- **Anything to grade.** There is no target configuration and no check.

## When you're done

```sh
astrona destroy firewalld-zones-playground
```

(`astrona destroy` takes the environment name, not the config path.)
