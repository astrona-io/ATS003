# Chapter 1: NTP Client Time Synchronization

Modern systems use **Chrony** to manage system time. 

Key config options inside "/etc/chrony/chrony.conf":
*   "server": Adds a static timing host.
*   "pool": Adds a dynamic pool of hosts.
*   "iburst": Sends an initial burst of 8 rapid packets for immediate synchronization on startup.
*   "makestep": Stepped clock corrections instead of slewing if offset is high.

---

## Guided Practice Lab 1: NTP Client Setup

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-041
```
Gain root:
```bash
sudo -i
```

### Step 2: Configure client sources
Open "/etc/chrony/chrony.conf":
```bash
nano /etc/chrony/chrony.conf
```
Add the following source lines:
```text
server ntp.ubuntu.com iburst minpoll 4 maxpoll 8
```
Save and exit. Restart the service and verify active sync:
```bash
systemctl restart chronyd
chronyc sources -v
chronyc tracking
```
