# Chapter 1: Persistent Network Managers

NetworkManager separates physical interface devices from logical connections profile settings.

To configure a persistent static connection profile:
```bash
sudo nmcli connection add type ethernet con-name static-eth0 ifname eth0 ip4 10.0.0.10/24 gw4 10.0.0.1
sudo nmcli connection modify static-eth0 ipv4.dns "8.8.8.8"
sudo nmcli connection modify static-eth0 ipv4.method manual
sudo nmcli connection up static-eth0
```

---

## Guided Practice Lab 1: nmcli Configuration

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-061
```
Gain root:
```bash
sudo -i
```

### Step 2: Configure static connections
Add connection:
```bash
nmcli connection add type ethernet con-name static-eth0 ifname eth0 ip4 192.168.10.150/24 gw4 192.168.10.1
```
Set DNS parameters persistently:
```bash
nmcli connection modify static-eth0 ipv4.dns "8.8.8.8"
nmcli connection modify static-eth0 ipv4.method manual
```
Activate the connection:
```bash
nmcli connection up static-eth0
```
