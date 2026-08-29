# DNS Verification with dig — Playground

- **ID:** PLAYGROUND
- **Slug:** dns-dig-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM running a local authoritative BIND server for the made-up zone
`lab.example` (and its reverse zone), so every `dig` query type — A, AAAA, MX,
CNAME, TXT, NS, SOA, PTR, AXFR — resolves offline with no internet DNS.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy dns-dig-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`dns-dig-playground`), not the config path. `astrona submit` and `astrona test`
do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Installs dig + BIND, loads the `lab.example` zone |
| `docs/overview.md` | The zone contents and queries to try |
