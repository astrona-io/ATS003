# NTP Client Time Synchronization — Playground

- **ID:** PLAYGROUND
- **Slug:** ntp-chrony-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Two-VM sandbox: a local chrony NTP server and a chrony client on an isolated
segment, for configuring sources and watching the client lock on with
`chronyc`. The client starts with no sources; the server serves local time at
stratum 8.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ntp-chrony-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`ntp-chrony-playground`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (two qemu VMs + bootstrap only) |
| `bootstrap/prepare-common.sh` | Installs chrony on both VMs |
| `bootstrap/prepare-server.sh` | Configures `ntp-server` as a local NTP source |
| `bootstrap/prepare-client.sh` | Clears default sources on `ntp-client` |
| `docs/overview.md` | What the environment contains and ideas to try |
