# Solution Walkthrough

You build a bridge and a bond on the three practice interfaces, then write both into a Netplan file so they survive a reboot. Everything runs in the virtual machine's `terminal`. None of these steps touch the management interface, the antenna that carries your link to mission control.

Two devices, one pattern each:

| Device | Create it | Add members |
| --- | --- | --- |
| Bridge `br0` | `sudo ip link add name br0 type bridge` | `sudo ip link set dummy0 master br0` |
| Bond `bond0` | `sudo ip link add bond0 type bond mode active-backup` | set the member **down**, then `master bond0`, then up |

Persistence for both goes in one file under `/etc/netplan/`.

## The feedback loop

Grading runs from your **own terminal**, the shell where you typed `astrona run`, not inside the virtual machine:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-020/module-01/labs/lab-01
```

There are five checks. Before you start, all of them fail:

```text
FAIL  bridge-master
FAIL  bridge-forwarding
FAIL  bond-mode
FAIL  bond-active-slave
FAIL  persistence
```

Run it now, and again after every step.

---

## Step 1: Look at the practice interfaces

On the virtual machine, list the interfaces:

```bash
ip -brief link show
```

You should see `dummy0`, `dummy1` and `dummy2`, all `UP`. Those are the three interfaces you use. Leave the management interface (the one with a real IP address) alone.

---

## Step 2: Build the bridge

Create the bridge, bring it up, and attach `dummy0` to it:

```bash
sudo ip link add name br0 type bridge
sudo ip link set br0 up
sudo ip link set dummy0 master br0
```

Check the membership:

```bash
bridge link show
```

You want a line for `dummy0` that says `master br0`. Right after you attach it, the port spends about 15 seconds in `listening` and `learning` before it reaches `state forwarding`. That is the Spanning Tree Protocol's start-up delay. Either wait and check again, or turn spanning tree off on this bridge so it forwards straight away:

```bash
sudo ip link set br0 type bridge stp_state 0
```

**Run the check** in your own terminal. `bridge-master` passes straight away. `bridge-forwarding` passes once the port is forwarding: at once if you turned spanning tree off, otherwise after about 15 seconds.

---

## Step 3: Build the bond

Create the bond in active-backup mode:

```bash
sudo ip link add bond0 type bond mode active-backup
```

The kernel refuses to attach an interface that is still `UP`. So bring each member down, attach it, then bring everything back up:

```bash
sudo ip link set dummy1 down
sudo ip link set dummy2 down
sudo ip link set dummy1 master bond0
sudo ip link set dummy2 master bond0
sudo ip link set dummy1 up
sudo ip link set dummy2 up
sudo ip link set bond0 up
```

Check the bond's state:

```bash
cat /proc/net/bonding/bond0
```

You want to see `Bonding Mode: fault-tolerance (active-backup)`, both `Slave Interface: dummy1` and `Slave Interface: dummy2`, and a `Currently Active Slave:` that names `dummy1` or `dummy2` (not `None`).

**Run the check.** `bond-mode` and `bond-active-slave` now pass.

---

## Step 4: Make br0 and bond0 persistent

Write both devices into a new Netplan file. Do not edit the cloud-init file that configures the management interface.

Save this as `/etc/netplan/99-lab-bridge-bond.yaml` (for example with `sudo nano /etc/netplan/99-lab-bridge-bond.yaml`; use spaces and keep the indentation exactly):

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    dummy0: {}
    dummy1: {}
    dummy2: {}
  bridges:
    br0:
      interfaces: [dummy0]
  bonds:
    bond0:
      interfaces: [dummy1, dummy2]
      parameters:
        mode: active-backup
```

- `bridges:` and `bonds:` are the top-level keys Netplan uses for these device types.
- `interfaces:` lists the members of each.
- `parameters: mode: active-backup` sets the bond mode.

Apply it: tighten the file's permissions, check that it parses, and apply it:

```bash
sudo chmod 600 /etc/netplan/99-lab-bridge-bond.yaml
sudo netplan generate
sudo netplan apply
```

`netplan generate` only checks that the file parses. If `netplan apply` prints a note about the dummy interfaces, that is fine: the `br0` and `bond0` declarations are what the check reads.

**Run the check.** `persistence` now passes. All five are green.

---

## Step 5: Submit

When `astrona submit` shows all five as `PASS`:

```text
PASS  bridge-master
PASS  bridge-forwarding
PASS  bond-mode
PASS  bond-active-slave
PASS  persistence
```

Submit from your own terminal:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-020/module-01/labs/lab-01
```

---

## If a check stays red

- **`bond-mode` fails, and attaching gave "Device or resource busy".** The member was still `UP` when you ran `ip link set … master bond0`. Set `dummy1` and `dummy2` **down** first, attach them, then bring them up.
- **`bridge-forwarding` stays red.** Spanning tree is still in `listening` or `learning`. Wait about 15 seconds and check again, or run `sudo ip link set br0 type bridge stp_state 0` for instant forwarding.
- **`bond-active-slave` fails.** The members are attached but still down. Bring `dummy1` and `dummy2` up and read `/proc/net/bonding/bond0` again.
- **`persistence` fails.** The exact keys `br0:` and `bond0:` must both appear in a file matching `/etc/netplan/*.yaml`. Check that the file name ends in `.yaml` and the keys are spelled exactly.
