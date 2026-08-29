# Software Bridging — Playground

- **ID:** PLAYGROUND
- **Slug:** linux-bridging-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Clean Linux host with two NICs on one shared segment for exploring Linux
bridges, the forwarding database, and STP loop blocking.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy linux-bridging-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `linux-bridging-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
