# Solution

## Step 0: Inventory the interfaces

```bash
ip -br link show
```

Confirm `dummy0`, `dummy1`, and `dummy2` exist and are currently unconfigured/free to be enslaved — enslaving an interface that already holds important config (like an active IP a running service depends on) without moving that config first will cause an outage.

Also identify the host's primary/management interface so it never accidentally gets enslaved:

```bash
IFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "$IFACE"
```

`dummy0`, `dummy1`, and `dummy2` are separate, disposable interfaces from whatever `$IFACE` reports — the bridge/bond work below only ever touches the dummy interfaces, never the default-route NIC.

## Step 1: Build the bridge live

```bash
sudo ip link add name br0 type bridge
sudo ip link set dummy0 master br0
sudo ip link set br0 up
sudo ip link set dummy0 up
```

Check `man ip-link` and search `/master` — `ip link set DEVICE master BRIDGE` is the command that actually enslaves an interface to a bridge; it's a property of the enslaved device (`dummy0`), not an operation on the bridge itself, which is a subtlety worth confirming in the man page rather than guessing the argument order. Both the bridge and the enslaved interface need to be administratively `up` — a bridge with a down member interface won't forward through it.

If `dummy0` previously held an IP address meant for the host, move it to `br0` instead:

```bash
sudo ip addr add 192.168.10.72/24 dev br0
```

This reflects the conceptual point from Study First: once enslaved, `dummy0` is a pure L2 port and shouldn't carry the host's own IP.

## Step 2: Build the bond live

```bash
sudo modprobe bonding
sudo ip link add bond0 type bond mode active-backup miimon 100
sudo ip link set dummy1 down
sudo ip link set dummy2 down
sudo ip link set dummy1 master bond0
sudo ip link set dummy2 master bond0
sudo ip link set dummy1 up
sudo ip link set dummy2 up
sudo ip link set bond0 up
```

Check `modinfo bonding` before this step if you're unsure of the exact mode name — it prints the full parameter description for `mode`, including every valid mode string (`balance-rr`, `active-backup`, `balance-xor`, `broadcast`, `802.3ad`, `balance-tlb`, `balance-alb`) and their numeric equivalents, straight from the kernel module itself, with no internet required.

`mode active-backup` means only one slave carries traffic at a time, with automatic failover — exactly the "NIC/cable failure shouldn't take the host off the network" requirement, and critically, it requires zero special configuration on the connected switch, unlike `802.3ad`. `miimon 100` tells the bonding driver to check link state (via MII) every 100 milliseconds — this is what actually detects a failed link quickly enough to fail over; without a `miimon` interval, the bond has no reliable way to notice a dead link at all.

Bringing the slave interfaces `down` before assigning `master bond0` and back `up` afterward avoids transient states where an interface is half-configured — a defensive habit worth keeping even when it isn't strictly required by the kernel.

## Step 3: Persist the bridge — Netplan path

```yaml
# /etc/netplan/70-app-srv1-br0.yaml
network:
  version: 2
  ethernets:
    dummy0: {}
  bridges:
    br0:
      interfaces: [dummy0]
      addresses:
        - 192.168.10.72/24
```

Check `man 5 netplan` and search for `bridges:` — it's a top-level key parallel to `ethernets:`, and the member interface(s) are listed under `interfaces:`. The plain `dummy0: {}` entry above tells Netplan the interface exists but should not be configured with its own IP — all addressing moves to `br0`.

## Step 4: Persist the bond — Netplan path

```yaml
# /etc/netplan/71-app-srv1-bond0.yaml
network:
  version: 2
  ethernets:
    dummy1: {}
    dummy2: {}
  bonds:
    bond0:
      interfaces: [dummy1, dummy2]
      parameters:
        mode: active-backup
        mii-monitor-interval: 100
```

Check `man 5 netplan` and search for `bonds:` and `parameters:` — the bonding-specific options (mode, mii-monitor-interval, and others) live nested under `parameters:`, distinct from the top-level bond definition.

```bash
sudo netplan generate
sudo netplan apply
```

## Step 5: The NetworkManager equivalents (if that's the active stack instead)

```bash
# Bridge
sudo nmcli con add type bridge ifname br0 con-name br0
sudo nmcli con add type bridge-slave ifname dummy0 master br0
sudo nmcli con mod br0 ipv4.addresses 192.168.10.72/24 ipv4.method manual

# Bond
sudo nmcli con add type bond ifname bond0 con-name bond0 mode active-backup miimon 100
sudo nmcli con add type bond-slave ifname dummy1 master bond0
sudo nmcli con add type bond-slave ifname dummy2 master bond0
sudo nmcli con up bond0
sudo nmcli con up br0
```

Check `man nmcli` and search `/bond-slave` and `/bridge-slave` — these are distinct connection *types*, not options on the main bond/bridge connection, which is a common point of confusion for anyone more used to `ip link set master`.

## Verification

```bash
ip -br link show
```

Expected (abbreviated): `br0` and `bond0` shown as `UP`, with `dummy0` showing `br0` as master and `dummy1`/`dummy2` showing `bond0` as master.

```bash
bridge link show
```

Expected:

```text
3: dummy0: <BROADCAST,MULTICAST,UP> mtu 1500 master br0 state forwarding
```

Check `man bridge` if the `state forwarding` field is unfamiliar — it confirms the bridge's spanning-tree state has settled and the port is actively forwarding, not blocked.

```bash
cat /proc/net/bonding/bond0
```

Expected (abbreviated):

```text
Bonding Mode: fault-tolerance (active-backup)
Primary Slave: None
Currently Active Slave: dummy1
MII Status: up

Slave Interface: dummy1
MII Status: up
...
Slave Interface: dummy2
MII Status: up
...
```

`Currently Active Slave: dummy1` proves the bond is live and has selected an active member, exactly the "prove which interface is active without generating traffic" check from Study First.

## Command Summary

```bash
ip -br link show
IFACE=$(ip -o -4 route show to default | awk '{print $5}')

sudo ip link add name br0 type bridge
sudo ip link set dummy0 master br0
sudo ip link set br0 up
sudo ip link set dummy0 up
sudo ip addr add 192.168.10.72/24 dev br0

sudo modprobe bonding
sudo ip link add bond0 type bond mode active-backup miimon 100
sudo ip link set dummy1 down
sudo ip link set dummy2 down
sudo ip link set dummy1 master bond0
sudo ip link set dummy2 master bond0
sudo ip link set dummy1 up
sudo ip link set dummy2 up
sudo ip link set bond0 up

# Netplan persistence:
sudo $EDITOR /etc/netplan/70-app-srv1-br0.yaml
sudo $EDITOR /etc/netplan/71-app-srv1-bond0.yaml
sudo netplan generate
sudo netplan apply

ip -br link show
bridge link show
cat /proc/net/bonding/bond0
```
