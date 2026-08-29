# Network Interfaces and IP Addressing — Playground

- **ID:** PLAYGROUND
- **Slug:** network-interfaces-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single Linux host with a management interface plus two extra NICs — one
addressed with an IPv4 and an IPv6 address, one UP with no address — for
exploring `ip link show`, `ip addr show`, interface state, and IPv4 / IPv6
prefix lengths.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy network-interfaces-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `network-interfaces-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
