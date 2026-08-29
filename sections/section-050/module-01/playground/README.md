# Nginx Reverse Proxy — Playground

- **ID:** PLAYGROUND
- **Slug:** nginx-proxy-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM with nginx and two request-echoing backend apps on localhost
(`127.0.0.1:9001`, `:9002`), for writing `proxy_pass` and `location` blocks and
seeing exactly what nginx forwards — path rewriting, `Host`, `X-Forwarded-For`,
`upstream` round-robin, `502` on a dead backend.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy nginx-proxy-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`nginx-proxy-playground`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Installs nginx + two echo backends |
| `docs/overview.md` | What the environment contains and ideas to try |
