# Make The Bond Last

Astronaut, a bond built with `ip` is chalked on the console: the next restart wipes it. In this part you prove that with a reboot, learn which systems write a bond into the flight manual so it comes back, and check what real redundancy needs beyond two cables.

## Runtime against persistent configuration

A bond built with `ip` is **runtime** configuration, and a restart normally removes it. A persistent bond is written into the flight manual for the communications array: the distribution's network-management system.

### Who keeps the configuration

On Linux that system is one of NetworkManager, Netplan, `systemd-networkd`, `ifupdown`, or files that belong to one distribution. On Ubuntu 24.04, Netplan is the flight manual: its YAML files live under `/etc/netplan/`, and it hands them to a communications officer (`systemd-networkd` or NetworkManager) that sets up the interfaces.

Do not configure the same interfaces through more than one of these systems. Two officers with different orders make interfaces change state when you do not expect it.

### See it in your playground

<!-- astrona:playground:renew -->

This restarts the whole training ship and drops your SSH session for about a minute. Reconnect with `astrona ssh linux-bonding-playground`.

```sh
sudo reboot
```

After you reconnect, look for the bond's state file:

```sh
cat /proc/net/bonding/bond0
```

Expect:

```text
cat: /proc/net/bonding/bond0: No such file or directory
```

The bonding *driver* is still loaded, because the playground's start-up script loads it. But `bond0` and everything you built with `ip` are gone. Anything that must come back after a reboot has to be written into one of the network-management systems above.

## High-availability considerations

Bonding removes some single points of failure, not all. A bond is only as strong as the weakest piece that both members share.

### What to check

For real redundancy, check whether the members use:

- different physical network cards and different cables;
- different switch ports, and ideally different switches;
- independent power;
- independent paths beyond the switch.

Two members into the *same* switch survive a cable or port fault, but not a failure of the switch itself. Members split across two switches need a design the switches support, such as switch stacking or multi-chassis link aggregation (MLAG).

## Common pitfalls

> [!WARNING]
> - **Trusting a bond built with `ip` to survive a reboot.** It is runtime state only. Declare it in Netplan or NetworkManager if it must come back.
> - **Configuring one interface in two systems.** Netplan and a separate NetworkManager profile for the same interface fight each other. Pick one.
> - **Both members into one switch and calling it redundant.** That covers a port or cable fault, not a switch failure or a broken path beyond it.

## Declare the practice topology in Netplan

In the independent lab, the dummy interfaces already exist and are recreated at boot. Save the following as `/etc/netplan/99-lab.yaml`; it adds only the practice topology and leaves the management interface configuration in place.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    dummy1: {}
    dummy2: {}
  bonds:
    bond0:
      interfaces:
      - dummy1
      - dummy2
      parameters:
        mode: active-backup
```

The `interfaces` list attaches the supplied members. `mode: active-backup` selects one active bond member. Validate the file, apply it, then check kernel state:

```bash
sudo chmod 600 /etc/netplan/99-lab.yaml
sudo netplan generate
sudo netplan apply
cat /proc/net/bonding/bond0
```

A saved declaration alone does not prove persistence. Reboot the lab VM, reconnect and repeat the live checks.

## Practice: Build a persistent active-backup bond

Create bond0 using only the supplied practice interfaces. Check active-backup mode and the active member. Persist bond0 in Netplan and verify it after reboot. This lab starts independently; changes in the playground do not carry over.

Pause the playground first:

```bash
astrona stop linux-bonding-playground
```

Read the [task](labs/lab-01/question.md), then start the lab:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-01/labs/lab-01
```

Use the inspection commands while working. Submit once all tasks are complete; submission ends the environment.

Resume the playground afterwards:

```bash
astrona start linux-bonding-playground
```
