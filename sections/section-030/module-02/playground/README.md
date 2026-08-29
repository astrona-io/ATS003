# firewalld Zones and Services — Playground

- **ID:** PLAYGROUND
- **Slug:** firewalld-zones-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Clean Ubuntu host running firewalld at its defaults, for exploring zones,
interface assignment, services, and ports with `firewall-cmd`. Includes `curl` /
`python3` for test traffic and a second interface on an isolated segment for
zone-assignment experiments.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy firewalld-zones-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`firewalld-zones-playground`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
