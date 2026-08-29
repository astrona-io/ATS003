# Netplan YAML Configurations — Playground

- **ID:** PLAYGROUND
- **Slug:** netplan-yaml-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM with a spare NIC on an isolated `192.168.130.0/24` segment for writing
netplan YAML, rendering it to `systemd-networkd` with `netplan generate`,
trialling it with `netplan try`'s 120-second auto-rollback, and applying it —
all without touching the management interface's own netplan file.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy netplan-yaml-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`netplan-yaml-playground`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Confirms netplan, names the spare NIC, tightens file perms |
| `docs/overview.md` | What the environment contains and ideas to try |
