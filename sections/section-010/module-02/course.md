# Chapter 2: Static Hostname Management

Systemd manages three classes of hostnames:
1.  **Static**: Persistent hostname stored in "/etc/hostname".
2.  **Transient**: Runtime dynamic hostname received from DHCP or mDNS.
3.  **Pretty**: Free-form UTF-8 description metadata string.

We manage these using the "hostnamectl" utility.

---

## Guided Practice Lab 2: Hostname Management

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-012
```
Gain root:
```bash
sudo -i
```

### Step 2: Set Hostnames
Verify current chassis, virtualization, and hostname states:
```bash
hostnamectl status
```
Persistently set your static hostname:
```bash
hostnamectl set-hostname prod-app-01
```
Set a pretty, user-friendly hostname description:
```bash
hostnamectl set-hostname "Marketing Server - Primary" --pretty
```
Verify the updates:
```bash
cat /etc/hostname
hostnamectl status
```
