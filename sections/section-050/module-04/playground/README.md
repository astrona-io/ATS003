# OpenSSH Client — Playground

- **ID:** PLAYGROUND
- **Slug:** ssh-client-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM with a visitor user `cadet`, a remote user `pilot`, two throwaway
`sshd` services (ports 2222 and 2223) and a loopback-only web service on 8081,
so keys, `known_hosts`, `~/.ssh/config`, jump hosts and tunnels all have
something to work against.

## Run it

```sh
astrona run -c .
astrona destroy ssh-client-playground
```

`astrona destroy` takes the environment name, not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Creates users, two sshd services and the web service |
| `docs/overview.md` | What is in the box and what to try |
