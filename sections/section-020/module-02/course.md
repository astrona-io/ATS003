# Chapter 2: Software Bridging

A software bridge is a virtual Layer 2 switch inside the Linux kernel. Interfaces connected to a bridge act as member ports on a switch and must not have IP addresses assigned. Any static IP or DHCP lease must be configured on the bridge interface itself.

---

## Guided Practice Lab 2: Software Bridging

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-022
```
Gain root:
```bash
sudo -i
```

### Step 2: Create and Bind a Bridge
Initialize a software bridge:
```bash
ip link add name br0 type bridge
```
Subordinate interface "eth3" as a port of bridge "br0":
```bash
ip link set eth3 master br0
```
Activate the links:
```bash
ip link set br0 up
ip link set eth3 up
```
Verify the bridge memberships:
```bash
bridge link show
```
