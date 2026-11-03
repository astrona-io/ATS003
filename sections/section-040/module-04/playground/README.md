# DNS Client Resolution — Playground

- **ID:** PLAYGROUND
- **Slug:** dns-resolver-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM with `systemd-resolved` at its defaults and a BIND server for
`lab.example` on a dummy interface (`10.55.0.53`), so `/etc/hosts`,
`nsswitch.conf`, the stub resolver, `resolvectl`, drop-ins and search domains
all have something to work against.

## Run it

```sh
astrona run -c .
astrona destroy dns-resolver-playground
```

`astrona destroy` takes the environment name, not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Creates `dns0` and the BIND zone |
| `docs/overview.md` | What is in the box and what to try |
