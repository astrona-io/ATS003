# Chapter 2: Netplan YAML Configurations

Ubuntu Server reads declarative configuration files written in YAML under "/etc/netplan/". 

Tabs are strictly prohibited for indentation; you must use spaces.

Example Netplan profile:
```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
```

---

## Guided Practice Lab 2: Netplan YAML

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-062
```
Gain root:
```bash
sudo -i
```

### Step 2: Configure Netplan profile
Open netplan configuration file:
```bash
nano /etc/netplan/01-netcfg.yaml
```
Write the static network block using spaces only, save and exit, and run a safe trial:
```bash
netplan try
```
