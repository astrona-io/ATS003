# Chapter 2: NTP Server Mode and Stratums

To reduce internet bandwidth, administrators run a private time server. By default, Chrony rejects client queries. Use the "allow" directive in "chrony.conf" to grant access to internal subnet ranges.

If air-gapped, set "local stratum 10" to authorize local clock fallback.

---

## Guided Practice Lab 2: Chrony Server Mode

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-042
```
Gain root:
```bash
sudo -i
```

### Step 2: Open access to clients
Open "/etc/chrony/chrony.conf":
```bash
nano /etc/chrony/chrony.conf
```
Append the following access line:
```text
allow 192.168.10.0/24
```
Save and exit. Restart the service, open firewall UDP port 123, and monitor packets:
```bash
systemctl restart chronyd
ufw allow 123/udp
chronyc serverstats
```
