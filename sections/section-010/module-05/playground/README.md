# Dynamic Addressing with DHCP — Playground

- **ID:** PLAYGROUND
- **Slug:** dhcp-client-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM with a linked pair of virtual antennas. `dhcpsrv0` (`10.77.0.1/24`)
runs a `systemd-networkd` DHCP server. `dhcp0` is the unconfigured client end.

## Run it

```sh
astrona run -c .
astrona destroy dhcp-client-playground
```

`astrona destroy` takes the environment name, not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Creates the veth pair and the DHCP server |
| `docs/overview.md` | What is in the box and what to try |
