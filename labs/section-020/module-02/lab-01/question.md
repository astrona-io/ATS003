# Question

Solve this question on: `terminal`

## Scenario

You are preparing this host for a redundant network layout: one Layer-2
bridge that other interfaces can be plugged into, and one fault-tolerant
bond that survives losing a link.

The VM has only one real NIC — the management interface your session runs
on. Bridging or bonding it would cut you off, so the setup script has
already created three safe, disposable dummy interfaces: `dummy0`, `dummy1`,
and `dummy2`, all UP. Build everything on those.

## Tasks

1. **Bridge.** Create a bridge named `br0`, bring it administratively UP,
   and enslave `dummy0` to it. `dummy0` must end up with `master br0` and
   reach `state forwarding` (as shown by `bridge link show`).

2. **Bond.** Create a bond named `bond0` in **active-backup** mode, and
   enslave **both** `dummy1` and `dummy2` to it. `/proc/net/bonding/bond0`
   must report active-backup mode, both slave interfaces, and a current
   active slave that is not `None`.

3. **Persistence.** Declare both `br0` and `bond0` in on-disk network
   configuration — a file under `/etc/netplan/` or a NetworkManager
   connection — so they come back after a reboot. Live-only kernel state
   from `ip link add` does not count.
