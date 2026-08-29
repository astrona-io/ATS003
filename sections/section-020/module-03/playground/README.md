# Multi-Interface Static Routing — Playground

- **ID:** PLAYGROUND
- **Slug:** static-routing-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Multi-interface Linux host (two extra NICs on 10.0.0.0/24 and 192.168.70.0/24)
for exploring static routes, longest-prefix matching, route metrics, source
selection, and `ip route get`.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy static-routing-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `static-routing-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
