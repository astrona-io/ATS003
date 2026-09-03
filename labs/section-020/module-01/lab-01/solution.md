# Solution Walkthrough

You will build a bridge and a bond on the three dummy interfaces, then write
both into a config file so they survive a reboot. Everything runs on the
VM's `terminal`. None of these steps touch the management interface.

Two devices, one pattern each:

| Device | Create it | Add members |
| --- | --- | --- |
| Bridge `br0` | `sudo ip link add name br0 type bridge` | `sudo ip link set dummy0 master br0` |
| Bond `bond0` | `sudo ip link add bond0 type bond mode active-backup` | set slave **down**, then `master bond0`, then up |

Persistence for both goes in one `/etc/netplan/` file.

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`, not inside the VM:

```bash
astrona test -c labs/section-020/module-01/lab-01
```

Five checks:

```text
FAIL  bridge-master
FAIL  bridge-forwarding
FAIL  bond-mode
FAIL  bond-active-slave
FAIL  persistence
```

Run it now, then again after every step.

---

## Step 1: Look at the dummy interfaces

On the VM:

```bash
ip -brief link show
```

You should see `dummy0`, `dummy1`, `dummy2`, all `UP`. Those are the three
NICs you will use. Leave the management interface (the one with a real IP)
alone.

---

## Step 2: Build the bridge

Create the bridge, bring it up, and put `dummy0` into it:

```bash
sudo ip link add name br0 type bridge
sudo ip link set br0 up
sudo ip link set dummy0 master br0
```

Check the membership:

```bash
bridge link show
```

You want a line for `dummy0` that says `master br0`. Right after you enslave
it, the port spends about 15 seconds in `listening` / `learning` before it
reaches `state forwarding` — that is the spanning-tree startup delay. Either
wait and re-check, or turn STP off on this bridge so it forwards
immediately:

```bash
sudo ip link set br0 type bridge stp_state 0
```

**Run the check** on the host terminal — `bridge-master` passes right away.
`bridge-forwarding` passes once the port is forwarding (immediately if you
disabled STP, otherwise after ~15 s).

---

## Step 3: Build the bond

Create the bond in active-backup mode:

```bash
sudo ip link add bond0 type bond mode active-backup
```

The kernel refuses to enslave an interface that is still UP, so bring each
one down, enslave it, then bring things back up:

```bash
sudo ip link set dummy1 down
sudo ip link set dummy2 down
sudo ip link set dummy1 master bond0
sudo ip link set dummy2 master bond0
sudo ip link set dummy1 up
sudo ip link set dummy2 up
sudo ip link set bond0 up
```

Check the bond state:

```bash
cat /proc/net/bonding/bond0
```

You want to see `Bonding Mode: fault-tolerance (active-backup)`, both
`Slave Interface: dummy1` and `Slave Interface: dummy2`, and a
`Currently Active Slave:` that names `dummy1` or `dummy2` (not `None`).

**Run the check** — `bond-mode` and `bond-active-slave` now pass.

---

## Step 4: Make br0 and bond0 persistent

Write both into a new Netplan file (do not edit the cloud-init file). On the
VM:

```bash
sudo nano /etc/netplan/99-lab-bridge-bond.yaml
```

Type this in. Use spaces, keep the indentation exactly:

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

- `bridges:` and `bonds:` are the top-level keys Netplan uses for these
  device types.
- `interfaces:` lists the members of each.
- `parameters: mode: active-backup` sets the bond mode.

Save and exit (`nano`: `Ctrl+O`, `Enter`, `Ctrl+X`), then tighten
permissions and apply:

```bash
sudo chmod 600 /etc/netplan/99-lab-bridge-bond.yaml
sudo netplan generate
sudo netplan apply
```

`netplan generate` just checks the file parses. If `netplan apply` prints a
note about the dummy interfaces, that is fine — the `br0` and `bond0`
declarations are what the check reads.

**Run the check** — `persistence` now passes. All five green.

---

## Step 5: Submit

When `astrona test` shows all five `PASS`:

```text
PASS  bridge-master
PASS  bridge-forwarding
PASS  bond-mode
PASS  bond-active-slave
PASS  persistence
```

Submit from the host terminal:

```bash
astrona submit -c labs/section-020/module-01/lab-01
```

---

## If a check stays red

- **`bond-mode` fails, enslave gave "Device or resource busy".** The slave
  was still UP when you ran `ip link set … master bond0`. Set `dummy1` and
  `dummy2` **down** first, enslave, then bring them up.
- **`bridge-forwarding` stays red.** Spanning tree is still in
  `listening`/`learning`. Wait ~15 seconds and re-check, or run
  `sudo ip link set br0 type bridge stp_state 0` for instant forwarding.
- **`bond-active-slave` fails.** The slaves are enslaved but still down.
  Bring `dummy1` and `dummy2` up and re-check `/proc/net/bonding/bond0`.
- **`persistence` fails.** The literal keys `br0:` and `bond0:` must both
  appear in a file matching `/etc/netplan/*.yaml`. Check the filename ends
  in `.yaml` and the keys are spelled exactly.
