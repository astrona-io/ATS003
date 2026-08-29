# Local Hostname Resolution — Playground

- **ID:** PLAYGROUND
- **Slug:** hostname-resolution-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single Linux host with its static hostname set to `prod-app-01` and a seeded
`/etc/hosts`, for exploring `/etc/hosts`, `getent hosts`, `getent ahostsv4` /
`ahostsv6`, the `hosts:` line in `/etc/nsswitch.conf`, and `hostnamectl`.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy hostname-resolution-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `hostname-resolution-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
