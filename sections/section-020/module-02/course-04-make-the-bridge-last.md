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

## Declare the practice topology in Netplan

In the independent lab, the dummy interfaces already exist and are recreated at boot. Save the following as `/etc/netplan/99-lab.yaml`; it adds only the practice topology and leaves the management interface configuration in place.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    dummy0: {}
  bridges:
    br0:
      interfaces:
      - dummy0
      parameters:
        stp: false
```

The `interfaces` list attaches the supplied members. `stp: false` disables spanning tree on this isolated one-port bridge. Validate the file, apply it, then check kernel state:

```bash
sudo chmod 600 /etc/netplan/99-lab.yaml
sudo netplan generate
sudo netplan apply
bridge link
```

A saved declaration alone does not prove persistence. Reboot the lab VM, reconnect and repeat the live checks.

## Practice: Build a persistent software bridge

Create br0 using only the supplied practice interfaces. Check bridge membership and forwarding state. Persist br0 in Netplan and verify it after reboot. This lab starts independently; changes in the playground do not carry over.

Pause the playground first:

```bash
astrona stop linux-bridging-playground
```

Read the [task](labs/lab-01/question.md), then start the lab:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-02/labs/lab-01
```

Use the inspection commands while working. Submit once all tasks are complete; submission ends the environment.

Resume the playground afterwards:

```bash
astrona start linux-bridging-playground
```
