# Nginx Load Balancers — Playground

- **ID:** PLAYGROUND
- **Slug:** nginx-lb-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM with nginx load-balancing across three labelled echo backends on
localhost (`127.0.0.1:9001-9003`), for trying round-robin, `weight=`,
`least_conn`, `hash` / `ip_hash`, `max_fails` ejection, `backup`, and
`proxy_next_upstream` — all observable with a `curl` loop.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy nginx-lb-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`nginx-lb-playground`), not the config path. `astrona submit` and `astrona test`
do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Installs nginx + three echo backends + a :8080 round-robin LB |
| `docs/overview.md` | What the environment contains and ideas to try |
