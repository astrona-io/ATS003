# Overview: PLAYGROUND — Software Bridging (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server host. Reach it with
  `astrona ssh linux-bridging-playground`.
- Three network interfaces:
  - the **management interface** carrying your SSH session — it has an IP;
    leave it alone;
  - **two extra bridge-port NICs**, both DOWN, both with no IP, both facing the
    same `192.168.60.0/24` Layer 2 segment. Find their kernel names with
    `ip -brief link show` (the ones that are not `lo` and not your SSH
    interface).
- Tools installed: `iproute2` (`ip`, `bridge`), `bridge-utils` (`brctl`),
  `ethtool`.
- No `br0` exists yet — `bridge link show` prints nothing until you create one
  and enslave a port.

## Things to try

- Create a bridge with `ip link add name br0 type bridge`, enslave one of the
  two NICs (`ip link set <dev> master br0`), bring `br0` and that port up, and
  read `bridge link show` and `ip link show master br0`.
- Assign `192.168.60.10/24` to `br0` (`ip addr add ... dev br0`) and confirm
  with `ip addr show dev br0` that the address sits on the bridge, not the port.
- Look at the forwarding database with `bridge fdb show br br0` — note which
  entries are `permanent` (the port's own MAC) and which are learned.
- **Loop and STP.** Both extra NICs face the *same* segment, so enslaving both
  is a deliberate Layer 2 loop. Enable STP **first**
  (`ip link set dev br0 type bridge stp_state 1`), *then* enslave and bring up
  the second port. Watch `bridge link show` settle with one port
  `state forwarding` and the other `state blocking`. `ip -d link show dev br0`
  shows the bridge's STP fields.
- Toggle STP back off (`stp_state 0`) and watch both ports go to `forwarding`.
  Keep an eye on the VM — with the loop unblocked, broadcast traffic can climb.
  Re-enable STP or bring one port down to calm it.
- Detach a port with `ip link set <dev> nomaster`, then delete the bridge with
  `ip link delete br0 type bridge`.
- Reboot the VM (`sudo reboot`) and confirm the bridge is gone — everything
  built with `ip` is non-persistent.

## Not shown here

- **DHCP on a bridge.** There is no DHCP server on the isolated segment, so
  running a DHCP client on `br0` has nothing to answer it. The idea is covered
  in the module text; the mechanics need a DHCP server this sandbox does not
  provision.

## When you're done

```sh
astrona destroy linux-bridging-playground
```

(`astrona destroy` takes the environment name, not the config path.)
