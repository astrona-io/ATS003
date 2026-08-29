# OpenSSH Server Hardening — Playground

- **ID:** PLAYGROUND
- **Slug:** ssh-hardening-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM with a throwaway second `sshd` on port 2222 (config
`/etc/ssh/sshd_test.conf`) and test users `alice` / `bob`, so every hardening
change and `Match` block can be broken and tested with `ssh -p 2222` without
risking the real `astrona` session on port 22.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ssh-hardening-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`ssh-hardening-playground`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Stands up sshd on :2222 + test users |
| `docs/overview.md` | What the environment contains and ideas to try |
