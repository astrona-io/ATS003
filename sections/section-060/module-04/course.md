# Chapter 4: Raw Packet Capturing (tcpdump)

To analyze raw network frames passing through system interface cards, use "tcpdump".

Common filter expressions:
*   "tcpdump -i eth0 -n not port 22"
*   "tcpdump -i eth0 -n host 192.168.1.10"
*   "tcpdump -i eth0 -n dst port 80 -w web.pcap"

---

## Guided Practice Lab 4: tcpdump Sniffing

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-064
```
Gain root:
```bash
sudo -i
```

### Step 2: Intercept raw traffic
Run a packet capture excluding your active SSH session:
```bash
tcpdump -i eth0 -n not port 22
```
Capture outbound traffic targeting TCP port 80 and save to a raw binary file:
```bash
tcpdump -i eth0 -n dst port 80 -c 5 -w dump.pcap
```
Read and parse the raw PCAP file:
```bash
tcpdump -n -r dump.pcap
```
