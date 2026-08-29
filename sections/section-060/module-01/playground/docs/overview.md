# Overview: PLAYGROUND — Persistent Network Managers (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh networkmanager-nmcli-playground`.
- **NetworkManager**, installed and running, but restricted (via
  `/etc/NetworkManager/conf.d/10-managed.conf`) to manage **only one spare
  NIC** on the isolated `192.168.120.0/24` segment.
- That spare NIC has **no connection profile** — that is what you build.
- The **management interface** carrying your SSH session is `unmanaged` by
  NetworkManager, so nothing you do with `nmcli` can drop the session.
- `nmcli`, `nmtui`, `ip`. Password-less `sudo`.
- The segment has **no DHCP server and no router**, so `ipv4.method auto` will
  not get a lease — `manual` is the realistic method here (and watching `auto`
  fail is itself informative).

Find the spare interface name with `ip -br link` or `nmcli device status` (it is
the one shown as `disconnected`, not `unmanaged`).

## Things to try

- **See the split.** `nmcli device status` — the spare NIC is `disconnected`
  (managed, no profile), the SSH NIC is `unmanaged`.
- **Build a static profile.**
  ```sh
  sudo nmcli connection add type ethernet con-name lab-static ifname <dev> \
      ipv4.method manual ipv4.addresses 192.168.120.50/24 ipv4.gateway 192.168.120.1 \
      ipv4.dns 192.168.120.1
  sudo nmcli connection up lab-static
  ```
  then `ip addr show <dev>` and `nmcli -f ipv4 connection show lab-static`.
- **Read the keyfile.** `sudo cat /etc/NetworkManager/system-connections/lab-static.nmconnection`
  — the on-disk form of everything `nmcli` just did (root-only, mode 600).
- **Modify and reapply.** `sudo nmcli connection modify lab-static
  +ipv4.addresses 192.168.120.51/24`, then `sudo nmcli connection up lab-static`
  — changes do not take effect until the profile is brought up again.
- **`up` / `down` vs `device disconnect`.** `nmcli connection down lab-static`
  vs `nmcli device disconnect <dev>` — and which one `autoconnect` overrides.
- **Autoconnect.** `sudo nmcli connection modify lab-static
  connection.autoconnect no`, `down`, `up` — see when NM brings it back on its
  own.
- **Two profiles, one NIC.** Add `lab-dhcp` (`ipv4.method auto`) on the same
  `ifname`, switch between them with `nmcli connection up`, and set
  `connection.autoconnect-priority` to pick the default.
- **Edit the keyfile directly.** Change a value in the `.nmconnection` file,
  then `sudo nmcli connection reload` and `sudo nmcli connection up lab-static`.
- **`nmcli -g` / `-t`.** `nmcli -g ipv4.addresses connection show lab-static` —
  the machine-readable forms for scripts.
- **Survive a reboot.** `sudo reboot`, reconnect, and confirm `lab-static` is
  still listed (and up, if autoconnect is on).

## What this sandbox does not set up

- **DHCP or a router on the lab segment.** `manual` addressing only.
- **Wi-Fi, bonds, bridges, VLANs.** All configurable with `nmcli` but not
  pre-seeded here.
- **netplan / systemd-networkd renderers.** The management NIC keeps whatever
  astrona uses; this playground is about NetworkManager on the spare NIC.
- **Anything to grade.**

## When you're done

```sh
astrona destroy networkmanager-nmcli-playground
```

(`astrona destroy` takes the environment name, not the config path.)
