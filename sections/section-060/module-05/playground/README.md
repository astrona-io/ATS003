# Network Troubleshooting Workflow — Playground

- **ID:** PLAYGROUND
- **Slug:** network-troubleshooting-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM with a dummy interface `lab0`, a web service `portal` on port 8443,
the name `portal.lab`, and helper commands that break one rung of the
troubleshooting ladder at a time.

## Run it

```sh
astrona run -c .
astrona destroy network-troubleshooting-playground
```

`astrona destroy` takes the environment name, not the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Creates `lab0`, the portal service and the helper commands |
| `docs/overview.md` | What is in the box and what to try |
