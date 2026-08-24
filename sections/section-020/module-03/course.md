# Chapter 3: Multi-Interface Static Routing

The routing table is the Layers 3 egress decision engine.

To query routes:
```bash
ip route show
```
To add static subnet routes:
```bash
ip route add 10.50.0.0/16 via 192.168.1.254 dev eth0
```
To trace packets across intermediate router hops, use "traceroute".

---

## Guided Practice Lab 3: Static Routing

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-023
```
Gain root:
```bash
sudo -i
```

### Step 2: Route Configuration & Lookups
Mock a route lookup decision to verify target ports:
```bash
ip route get 8.8.8.8
```
Configure static routes for network subnet "172.16.0.0/16" via gateway "10.0.0.1" out of "eth1":
```bash
ip route add 172.16.0.0/16 via 10.0.0.1 dev eth1
```
Trace the packet hops to confirm forwarding:
```bash
traceroute -n 172.16.100.5
```
