# Overview: PLAYGROUND — Network Interfaces and IPv4 & IPv6 Addressing (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server host. Reach it with
  `astrona ssh network-interfaces-playground`.
- Three network interfaces:
  - the **management interface** — has a DHCP address and carries your SSH
    session. Leave it alone;
  - an **extra NIC with addresses** — brought UP with one IPv4 address
    (`192.168.50.10/24`) and one IPv6 address (`2001:db8:50::10/64`) on the
    isolated `iface-net-a` segment;
  - an **extra NIC with no address** — brought UP on the isolated `iface-net-b`
    segment but deliberately left without an IP.
  - Find the kernel names with `ip -brief link show`.
- The **loopback** interface `lo` is always present, with `127.0.0.1/8` and
  `::1/128`.
- Tools installed: `iproute2` (`ip link` / `ip addr`), `iputils-ping`,
  `ethtool`.

## What you can see fully

- **List every interface and its state:** `ip link show` — name, `UP` /
  `DOWN`, `LOWER_UP` (carrier), MAC address, MTU.
- **List addresses per interface:** `ip addr show`, or one interface with
  `ip addr show dev <name>`.
- **An interface that is UP with no address** — the no-address NIC shows
  `state UP` under `ip link show` but has no `inet` / `inet6` line under
  `ip addr show`. UP is a link state, not a promise of reachability.
- **One interface holding both an IPv4 and an IPv6 address** at the same time,
  each with its own prefix length (`/24` and `/64`).
- **Prefix lengths** — compare the `/8` on loopback, `/24` on the IPv4 NIC,
  `/64` on the IPv6 address.
- **Add and remove addresses at runtime:**
  `sudo ip addr add 192.168.51.20/24 dev <nic-b>` then
  `sudo ip addr del 192.168.51.20/24 dev <nic-b>`. Runtime-only — a reboot
  clears anything added this way.
- **Bring an interface down and up:** `sudo ip link set <nic-b> down` then
  `sudo ip link set <nic-b> up`, and watch the state change in `ip link show`.
  Never do this to the management interface.

## What this sandbox cannot show

- **End-to-end reachability.** The two extra segments are isolated with no other
  host and no router, so `ping` to anything beyond the VM's own addresses will
  not get a reply. The module explains the difference between link state and
  reachability; this is where you see the link-state half only.
- **A default gateway in action.** There is no router on the extra segments, so
  traffic for other networks has nowhere to go from them. The management
  interface keeps its own default route — leave it as is.
- **Persistent addressing.** Everything `bootstrap/prepare.sh` and you set with
  `ip` is runtime-only. Making an address survive a reboot needs
  NetworkManager / Netplan / `systemd-networkd`, which this sandbox does not
  configure.

## When you're done

```sh
astrona destroy network-interfaces-playground
```

(`astrona destroy` takes the environment name, not the config path.)
