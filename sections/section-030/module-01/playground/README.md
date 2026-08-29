# Packet Filtering with nftables — Playground

- **ID:** PLAYGROUND
- **Slug:** nftables-filtering-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Clean Ubuntu host with an empty nftables ruleset for building tables, chains,
hooks, and rules from scratch and watching them filter live traffic. Includes
`ncat` / `curl` / `python3` for generating test traffic and a second local
address on an isolated segment for `ip saddr` rules.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy nftables-filtering-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`nftables-filtering-playground`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | OS prep run once at startup |
| `docs/overview.md` | What the environment contains and ideas to try |
