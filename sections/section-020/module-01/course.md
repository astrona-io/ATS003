# Chapter 1: Link Aggregation (Bonding)

Bonding aggregates multiple physical NICs into a single logical master link to guarantee high-availability or throughput.

Common modes:
*   "mode=1" (Active-Backup): Idle backup takes over on active links drop. No switch config needed.
*   "mode=5" (balance-tlb): Distributes outbound traffic based on link load. No switch config needed.
*   "mode=4" (802.3ad LACP): Dynamic aggregation. Requires switch-side aggregate grouping.

---

## Guided Practice Lab 1: Interface Bonding

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-021
```
Gain root:
```bash
sudo -i
```

### Step 2: Configure an Active-Backup Bond
Add the bond master link with MII link checking every 100ms:
```bash
ip link add name bond0 type bond mode active-backup miimon 100
```
Subordinate interfaces "eth1" and "eth2" to master "bond0":
```bash
ip link set eth1 down
ip link set eth1 master bond0
ip link set eth2 down
ip link set eth2 master bond0
```
Activate the bonds:
```bash
ip link set bond0 up
ip link set eth1 up
ip link set eth2 up
```
Verify bond status and active link carrier details:
```bash
cat /proc/net/bonding/bond0
```
