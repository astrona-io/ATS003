# Overview: PLAYGROUND — Network Troubleshooting Workflow (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh network-troubleshooting-playground`.
- `lab0`: a dummy interface with `10.66.0.10/24`.
- `portal.service`: a web page on port `8443`, all addresses.
- `portal.lab` in `/etc/hosts`, pointing at `10.66.0.10`.
- Helpers: `sudo break-link`, `sudo break-name`, `sudo break-firewall` and
  `sudo fix-all`.

## Things to try

- **Healthy ladder.** `ip -br link`, `ip -br addr`, `ip route get 10.66.0.10`,
  `getent hosts portal.lab`, `ss -tlnp`, `curl -v http://portal.lab:8443/`.
- **Break one rung.** Run a helper, then climb the ladder and find which rung
  failed. Compare the error messages. Run `sudo fix-all` after each one.
- **Path tools.** `ping -c 4`, `traceroute -n`, `tracepath -n`, `mtr -rwn -c 5`.
- **The wire.** `sudo tcpdump -ni any 'tcp port 8443'` in a second shell while
  you test a broken and a healthy portal.

## What this sandbox does not set up

- **A second machine.** `lab0` is a dummy interface, so no relay hops exist.
- **Anything to grade.**

## When you're done

```sh
astrona destroy network-troubleshooting-playground
```

(`astrona destroy` takes the environment name, not the config path.)
