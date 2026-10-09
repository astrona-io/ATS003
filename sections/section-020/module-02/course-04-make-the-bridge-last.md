# Make The Bridge Last

Astronaut, a bridge built with `ip` is chalked on the console: the next restart wipes it. In this part you prove that with a reboot, see which systems keep a bridge in the flight manual, and put bridges and bonds side by side so you never mix them up.

## Runtime against persistent configuration

Bridges built with `ip` are runtime only, and a restart normally removes them. A persistent bridge is written into the distribution's network-management system, the flight manual for the communications array.

### Who keeps the configuration

That system is one of NetworkManager, Netplan, `systemd-networkd`, `ifupdown`, or files that belong to one distribution. On Ubuntu 24.04, Netplan keeps its YAML files under `/etc/netplan/`.

Do not configure the same bridge through more than one of these systems. Conflicting configurations make addresses, routes and membership change when you do not expect it.

### See it in your playground

<!-- astrona:playground:renew -->

This restarts the whole training ship and drops your SSH session for about a minute. Reconnect with `astrona ssh linux-bridging-playground`.

```sh
sudo reboot
```

After you reconnect, look for the bridge:

```sh
ip link show dev br0
```

Expect:

```text
Device "br0" does not exist.
```

`br0` and every port you attached with `ip` are gone. Anything that must come back after a reboot has to be written into one of the network-management systems above.

## Bridges compared with bonds

A bridge and a bond both join interfaces, but they solve different problems. A bridge is a docking hub that connects separate lanes; a bond is two antennas teamed into one link.

### Side by side

| Technology | Primary purpose | Comparable physical device |
|---|---|---|
| Bridge | Connect multiple Layer 2 segments and virtual machines | Ethernet switch |
| Bond | Combine interfaces for redundancy or distribution | Link aggregation group |

### They stack

A bond can be a single bridge port:

```text
br0
└── bond0
    ├── eth1
    └── eth2
```

`eth1` and `eth2` provide the physical links, `bond0` gives redundancy or spreads the traffic, and `br0` gives Layer 2 connectivity and holds the IP address.

## Common pitfalls

> [!WARNING]
> - **Trusting a bridge built with `ip` to survive a reboot.** It is runtime state only. Declare it in Netplan or NetworkManager if it must come back.
> - **Confusing a bridge with a bond.** A bridge connects different segments, like a switch. A bond merges interfaces into one link. They are not interchangeable.
> - **Configuring one bridge in two systems.** Pick Netplan or NetworkManager, not both.

## Your mission: Software Bridging Lab

You can now build a bridge, attach a port and get it forwarding, and explain why the bridge needs persistent configuration. Now prove it in a graded mission: on three practice antennas (`dummy0`, `dummy1`, `dummy2`) you build a bridge `br0`, plus an active-backup bond `bond0`, and declare both in on-disk configuration so they survive a reboot.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop linux-bridging-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-02/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-022
astrona start linux-bridging-playground
```
