# Chapter 3: DNS Verification with dig

The Domain Name System (DNS) maps human-readable domains to numeric IPs. 

We query DNS zones directly using "dig":
*   "dig example.com A": Query IPv4 addresses.
*   "dig example.com MX": Query Mail Exchanger records.
*   "dig @1.1.1.1 example.com": Bypass system configurations and target a specific server directly.
*   "dig -x [IP]": Perform reverse lookups (PTR).

---

## Guided Practice Lab 3: DNS dig Queries

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-043
```
Gain root:
```bash
sudo -i
```

### Step 2: Perform Zone Queries
Query the default nameservers:
```bash
dig google.com mx
```
Query a targeted DNS server directly, stripping headers and printing only the raw IPv4 output:
```bash
dig @8.8.8.8 google.com +short
```
Perform a reverse lookup to find a host domain name:
```bash
dig -x 8.8.8.8
```
