# Overview: PLAYGROUND — Link Aggregation with Linux Bonding (Playground)

The members `bondport0` and `bondport1` are local dummy devices. Use them to inspect bond membership, link state and mode changes. They have no remote peer, so use the graded bonding lab for connectivity checks. The devices are recreated after reboot; any bond built with `ip` is temporary.


> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server host. Reach it with
  `astrona ssh linux-bonding-playground`.
- The management interface and two unaddressed dummy interfaces, `bondport0` and `bondport1`.
- Tools installed: `iproute2` (`ip`), `ethtool`, `kmod`, `ifenslave`.
- The `bonding` kernel module is loaded but **no bond interface exists yet** —
  `cat /proc/net/bonding/bond0` fails until you create `bond0` yourself.

## Things to try

- Create a temporary active-backup bond over the two member NICs with
  `ip link add ... type bond mode active-backup miimon 100`, enslave both
  interfaces, bring everything up, and read `/proc/net/bonding/bond0`.
- Assign `192.168.50.50/24` to `bond0` and watch which member shows as
  `Currently Active Slave`.
- Force a failover: `ip link set <active-member> down` and re-read
  `/proc/net/bonding/bond0` — note the `Currently Active Slave` change and the
  `Link Failure Count`.
- Tear the bond down (`ip link del bond0`) and rebuild it in `mode=balance-tlb`
  (mode 5). Compare `/proc/net/bonding/bond0` output between the two modes.
- Change `miimon` and observe the `MII Polling Interval (ms)` field.
- Reboot the VM (`sudo reboot`) and confirm the runtime bond is gone —
  everything created with `ip` is non-persistent.

## When you're done

```sh
astrona destroy linux-bonding-playground
```

(`astrona destroy` takes the environment name, not the config path.)
