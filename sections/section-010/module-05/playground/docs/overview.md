# Overview: PLAYGROUND — Dynamic Addressing with DHCP (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh dhcp-client-playground`.
- `dhcpsrv0`: `10.77.0.1/24`, with a `systemd-networkd` DHCP server.
  Pool `10.77.0.100` to `10.77.0.149`, lease time 10 minutes, router and DNS
  both `10.77.0.1`.
- `dhcp0`: the other end of the pair, with no configuration.

## Things to try

- **Turn it on.** Write `/etc/netplan/70-dhcp0.yaml` with `dhcp4: true`, then
  `sudo netplan apply` and `ip -br addr show dhcp0`.
- **Read the lease.** `networkctl status dhcp0`, `ip route`, and the file in
  `/run/systemd/netif/leases/`.
- **Refuse parts.** Add `dhcp4-overrides` with `use-routes: false` and
  `use-dns: false`, apply, and compare `ip route` before and after.
- **Watch DORA.** `sudo tcpdump -ni dhcp0 'udp port 67 or udp port 68'` while
  running `sudo networkctl renew dhcp0` in a second shell.

## What this sandbox does not set up

- **A real DHCP relay or a second server.**
- **Anything to grade.**
