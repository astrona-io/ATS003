# Chapter 1: IPv4 & IPv6 Addressing

Every network card on a host requires a Layer 3 Internet Protocol (IP) address. 

An IPv4 address consists of 32 bits, traditionally formatted as four decimal octets (e.g., "192.168.1.50/24"). 
An IPv6 address consists of 128 bits, written in hexadecimal notation separated by colons (e.g., "2001:db8::abcd/64").

To query your host's interfaces and links:
```bash
ip link show
ip addr show
```

---

## Guided Practice Lab 1: Interface IP Allocation

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-011
```
Gain root access:
```bash
sudo -i
```

### Step 2: Query and Assign Runtime IP
Verify active interface link adapters:
```bash
ip addr show
```
Assign a static IPv6 address to adapter "eth0":
```bash
ip addr add 2001:db8::abcd/64 dev eth0
```
Verify the assignment is active inside kernel memory:
```bash
ip addr show dev eth0
```
