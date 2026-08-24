# Chapter 2: firewalld Zones and Services

"firewalld" is a dynamic wrapper managing rules through **Zones** (trust levels like public, internal, trusted) and **Services** (XML port abstractions like http, https).

---

## Guided Practice Lab 2: firewalld Administration

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-032
```
Gain root:
```bash
sudo -i
```

### Step 2: Manage Zones and Services
Verify the active default zone:
```bash
firewall-cmd --get-default-zone
```
Change the interface "eth1" zone assignment persistently:
```bash
firewall-cmd --permanent --zone=internal --change-interface=eth1
```
Open access for HTTPS and a custom port range "8000-8010" persistently:
```bash
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --permanent --zone=public --add-port=8000-8010/tcp
```
Apply the changes:
```bash
firewall-cmd --reload
```
