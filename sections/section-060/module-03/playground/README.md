# Active Socket Diagnostics (ss) — Playground

- **ID:** PLAYGROUND
- **Slug:** ss-socket-diagnostics-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM pre-seeded with a spread of sockets — TCP listeners bound to all
addresses / localhost only / IPv6, a UDP listener, a Unix-domain listener, and
one long-lived established TCP connection — so every `ss` flag, state filter,
address form, and filter expression has something to show.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ss-socket-diagnostics-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`ss-socket-diagnostics-playground`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Starts the sample TCP/UDP/Unix listeners + a held connection |
| `docs/overview.md` | The socket inventory and `ss` invocations to try |
