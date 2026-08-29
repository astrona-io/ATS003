# Overview: PLAYGROUND — Multi-Interface Static Routing (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server host. Reach it with
  `astrona ssh static-routing-playground`.
- Three network interfaces:
  - the **management interface** — has an IP and carries the VM's real
    **default route**. Leave it and its default route alone;
  - **`10.0.0.50/24`** on the isolated `10.0.0.0/24` segment (`route-net-a`);
  - **`192.168.70.50/24`** on the isolated `192.168.70.0/24` segment
    (`route-net-b`).
  - Find the kernel names with `ip -brief -4 addr show`.
- Tools installed: `iproute2` (`ip route` / `ip rule` / `ip neigh` /
  `ip route get`), `iputils-ping`, `traceroute`.
- The routing table starts with only the two connected routes and the
  management default. Every static route, metric, and policy rule below is
  yours to add.

## What you can see fully

`ip route get` is a **route lookup**, not a packet send, so it works even
though no real router exists on either segment:

- Add a static route: `sudo ip route add 172.16.0.0/16 via 10.0.0.1 dev <dev-a>`
  — `10.0.0.1` is on-link for `10.0.0.0/24`, so the add succeeds. Confirm with
  `ip route show` and `ip route get 172.16.50.1`.
- Longest-prefix matching: add both `172.16.0.0/16` and `172.16.100.0/24` with
  different gateways, then `ip route get 172.16.100.5` and watch the `/24` win.
- Route metrics: add a second default route with a higher metric
  (`... metric 200`) and see `ip route show` order them; delete the lower one
  and watch selection move.
- Source-address selection: `ip route get 192.168.70.9` shows `src
  192.168.70.50`; `ip route get 10.0.0.9` shows `src 10.0.0.50`.
- `ip route replace`, `ip route del`, `ip rule show`,
  `ip route show table all`.

## What this sandbox cannot show

- **A reachable next-hop.** Nothing answers at `10.0.0.1` or `192.168.70.1`, so
  `ping -I <dev> 10.0.0.1` fails and `ip neigh` stays `FAILED`/empty for those
  addresses. The commands are still worth running to see that state.
- **A real `traceroute`.** With no router forwarding beyond the host, a trace to
  `172.16.100.5` just times out (`* * *`). The module explains what a working
  trace looks like.
- **Persistent routes.** Everything added with `ip route` is runtime-only; a
  reboot clears it. Persisting routes needs NetworkManager / Netplan /
  `systemd-networkd`, which this sandbox does not configure.

## When you're done

```sh
astrona destroy static-routing-playground
```

(`astrona destroy` takes the environment name, not the config path.)
