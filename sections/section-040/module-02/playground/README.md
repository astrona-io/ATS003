# NTP Server Mode and Stratums — Playground

- **ID:** PLAYGROUND
- **Slug:** ntp-server-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Two-VM sandbox: a chrony host you open up as an NTP server with `allow`, and a
client whose source flips from unreachable to synced the moment you do. The
server uses `local stratum` for a servable clock; no firewall, so `allow` is the
only gate.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ntp-server-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`ntp-server-playground`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (two qemu VMs + bootstrap only) |
| `bootstrap/prepare-common.sh` | Installs chrony on both VMs |
| `bootstrap/prepare-server.sh` | chrony with `local stratum 10`, no `allow` |
| `bootstrap/prepare-client.sh` | chrony pointed at the server, refused until allowed |
| `docs/overview.md` | What the environment contains and ideas to try |
