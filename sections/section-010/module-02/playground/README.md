# Managing Linux Hostnames — Playground

- **ID:** PLAYGROUND
- **Slug:** linux-hostnames-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single systemd Linux host with its static, transient, and pretty hostnames
seeded to three different values, for exploring `hostnamectl status`,
`hostnamectl set-hostname --static / --pretty / --transient`, and
`/etc/hostname`.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy linux-hostnames-playground
```

`astrona destroy` takes the environment name (`metadata.name` = `linux-hostnames-playground`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
