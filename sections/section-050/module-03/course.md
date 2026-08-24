# Chapter 3: OpenSSH Server Hardening

SSH is highly vulnerable to brute-force scanner scripts. Secure the daemon globally:
*   "X11Forwarding no"
*   "PasswordAuthentication no"

To override settings conditionally for users, groups, or subnet IP networks, append **Match Blocks** to the absolute bottom of "/etc/ssh/sshd_config".

---

## Guided Practice Lab 3: SSH Hardening

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-053
```
Gain root:
```bash
sudo -i
```

### Step 2: Implement Match Block Overrides
Open SSH config:
```bash
nano /etc/ssh/sshd_config
```
Verify global settings at the top are hardened, then append conditional blocks to the very bottom:
```text
Match User elena
    PasswordAuthentication yes
```
Save and exit. Test configuration file syntax and reload:
```bash
sshd -t
systemctl reload sshd
```
