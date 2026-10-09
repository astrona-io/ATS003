# Question

Solve this question on: `terminal`

## Scenario

Astronaut, you are preparing this training ship for a redundant network layout. It needs one bridge, a docking hub that other interfaces can be plugged into, and one bond, two antennas teamed so the link survives losing one of them.

The virtual machine has only one real network interface: the management interface your session runs on. Bridging or bonding it would cut you off. So the setup script has already created three safe practice interfaces, `dummy0`, `dummy1` and `dummy2`, all `UP`. Build everything on those three.

## Tasks

1. **Bridge.** Create a bridge named `br0` and bring it administratively `UP`. Attach `dummy0` to it as a port. `dummy0` must end up with `master br0` and reach `state forwarding`, as shown by `bridge link show`.

2. **Bond.** Create a bond named `bond0` in **active-backup** mode, and attach **both** `dummy1` and `dummy2` to it. `/proc/net/bonding/bond0` must report active-backup mode, both member interfaces (`Slave Interface: dummy1` and `Slave Interface: dummy2`), and a `Currently Active Slave` that is `dummy1` or `dummy2`, not `None`.

3. **Persistence.** Declare both `br0` and `bond0` in on-disk network configuration, either in a file under `/etc/netplan/` (ending in `.yaml`) or as NetworkManager connections, so they come back after a reboot. A bridge or bond that exists only in the kernel, made with `ip link add`, does not count.

Leave the management interface alone.
