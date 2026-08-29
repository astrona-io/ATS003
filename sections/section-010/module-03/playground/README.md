# Discovering Your Public IP Address — Playground

- **ID:** PLAYGROUND
- **Slug:** public-ip-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single Linux host with two private addresses in two RFC 1918 ranges
(`10.0.0.0/8` on the management NIC, `172.16.20.50/24` on a spare NIC) plus
`curl` and `dig`, for exploring `ip addr` / `ip route` and the public-egress
discovery commands (`curl ifconfig.me`, `dig ... myaddr.l.google.com`), which
need outbound Internet.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy public-ip-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `public-ip-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
