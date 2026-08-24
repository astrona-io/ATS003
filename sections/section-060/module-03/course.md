# Chapter 3: Active Socket Diagnostics (ss)

If a local server process cannot bind because its port is in use, or you suspect unauthorized listening sockets, use "ss":
*   "ss -tlpn": Shows listening TCP sockets, process owners, and raw PIDs.
*   "ss -uap": Shows UDP active sockets.

---

## Guided Practice Lab 3: ss Diagnostics

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-063
```
Gain root:
```bash
sudo -i
```

### Step 2: Investigate sockets
List listening TCP processes:
```bash
ss -tlpn
```
Locate the Process ID (PID) holding a target port open, and terminate it to free up resources:
```bash
kill -15 [PID]
```
