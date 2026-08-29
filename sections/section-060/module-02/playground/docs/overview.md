# Overview: PLAYGROUND — Netplan YAML Configurations (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh netplan-yaml-playground`.
- **Netplan**, native (renderer: `systemd-networkd`). `netplan`, `networkctl`,
  `ip`. Password-less `sudo`.
- One **spare NIC** on the isolated `192.168.130.0/24` segment — **no DHCP, no
  router**, so static addressing is the realistic case. It has **no netplan
  file**: writing one is the point. Its name is in `/root/lab-spare-iface` (also
  `ip -br link`).
- The **management interface** keeps its own cloud-init netplan file under
  `/etc/netplan/`. **Leave that file alone** — it configures the interface your
  SSH session uses.

## Things to try

Create `/etc/netplan/90-lab.yaml` (numbered high so it applies last), `chmod
600` it, and start with:

```yaml
network:
  version: 2
  ethernets:
    <spare-dev>:
      dhcp4: false
      addresses: [192.168.130.50/24]
```

- **See the merged config.** `sudo netplan get` — every netplan file combined
  into one view. `sudo netplan get ethernets.<spare-dev>` for one interface.
- **Render without applying.** `sudo netplan generate`, then look at what it
  produced: `cat /run/systemd/network/10-netplan-<spare-dev>.network`. Netplan
  is a front end; this is the `systemd-networkd` file it writes.
- **Safe trial with auto-rollback.** `sudo netplan try` — applies the config
  and starts a 120-second timer; press Enter to keep it, or wait and it reverts.
  The safety net for a change that might cut your connection.
- **Apply for real.** `sudo netplan apply`, then `ip -brief addr show
  <spare-dev>` and `networkctl status <spare-dev>`.
- **The tabs rule.** Put a literal tab in the file and run `sudo netplan get` —
  YAML rejects tabs for indentation; read the error.
- **Add routes and DNS.**
  ```yaml
      routes:
        - to: default
          via: 192.168.130.1
      nameservers:
        addresses: [192.168.130.1]
  ```
  (Nothing answers at `.1` here, but `netplan generate` still renders it.)
- **DHCP where there is none.** Set `dhcp4: true`, `sudo netplan apply`, and
  watch `networkctl status <spare-dev>` sit in `configuring` with no lease.
- **File ordering.** Add `/etc/netplan/99-override.yaml` setting a different
  address for the same interface — later files win **per key**, not
  whole-file. `sudo netplan get` shows the result.
- **Renderer.** Add `renderer: NetworkManager` under `network:` and re-run
  `sudo netplan generate` — different backend files.
- **Status.** `sudo netplan status --all`.

## What this sandbox does not set up

- **DHCP or a router on the lab segment.** Static addressing only.
- **Bonds, bridges, VLANs, Wi-Fi, tunnels.** All netplan-expressible, none
  pre-seeded.
- **NetworkManager as the default renderer.** It is `systemd-networkd` here;
  switching is one of the things to try.
- **Anything to grade.**

## When you're done

```sh
astrona destroy netplan-yaml-playground
```

(`astrona destroy` takes the environment name, not the config path.)
