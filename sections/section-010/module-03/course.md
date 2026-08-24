# Chapter 3: Public IP Discovery Behind NAT

Private IP subnets configured under RFC 1918 are non-routable on the Internet. Egress routers rewrite private source packets to public IP addresses using Source NAT (Masquerading). Because this happens on the router, local interfaces do not display public IPs.

To find your real public IP, you query external servers programmatically.

---

## Guided Practice Lab 3: Public IP Discovery

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-013
```
Gain root:
```bash
sudo -i
```

### Step 2: HTTP & DNS Egress Discovery
Query external plain-text mirrors using curl:
```bash
curl -s https://ifconfig.me
curl -s https://icanhazip.com
```
Bypass outbound HTTP/HTTPS firewalls by sending a specialized DNS TXT query to Google's nameservers on UDP port 53:
```bash
dig +short txt o-o.myaddr.l.google.com @ns1.google.com
```
