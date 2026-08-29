# Persistent Network Managers — Playground

- **ID:** PLAYGROUND
- **Slug:** networkmanager-nmcli-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM where NetworkManager owns exactly one spare NIC on an isolated
`192.168.120.0/24` segment, for building persistent connection profiles with
`nmcli` — `connection add` / `modify` / `up`, keyfiles under
`/etc/NetworkManager/system-connections/`, `ipv4.method manual` vs `auto`,
autoconnect, reboot persistence — without any risk to the SSH interface, which
NetworkManager leaves `unmanaged`.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy networkmanager-nmcli-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`networkmanager-nmcli-playground`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Installs NetworkManager, restricts it to the spare NIC |
| `docs/overview.md` | What the environment contains and ideas to try |
