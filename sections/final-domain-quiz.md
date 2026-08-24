# LFCS Networking: Final Domain Exam Simulator

This exam simulator tests your readiness for the Networking domain of the Linux Foundation Certified System Administrator (LFCS) exam.

## Exam Rules
*   **Time Cap:** 45 minutes
*   **Conditions:** Closed-book, terminal-focused.
*   **Format:** 20 scenario-based questions with diagnostic explanations.

---

## Exam Questions

### Q1: IP Address Mapping
You are persistently assigning a static IPv6 address of "2001:db8::abcd/64" to interface "eth1". Which command applies this address instantly at runtime?
*   **A)** "ip link set eth1 ipv6 2001:db8::abcd/64"
*   **B)** "ip addr add 2001:db8::abcd/64 dev eth1"
*   **C)** "sysctl net.ipv6.conf.eth1.address=2001:db8::abcd/64"
*   **D)** "ifconfig eth1 inet6 add 2001:db8::abcd/64"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** The "ip addr add" command is family-agnostic and handles both IPv4 and IPv6 allocations depending on the string format.
*   **Why others are incorrect:** 
    - *Option A* is incorrect because "ip link" manages link state, not Layer 3 addresses.
    - *Option C* is incorrect because sysctl cannot configure interface IP assignments.
    - *Option D* is incorrect because ifconfig is deprecated.
</details>

---

### Q2: Link aggregation metrics
Which bonding mode distributes outgoing packets based on current adapter load without requiring switch support?
*   **A)** "mode=1" (active-backup)
*   **B)** "mode=4" (802.3ad)
*   **C)** "mode=5" (balance-tlb)
*   **D)** "mode=0" (round-robin)

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** Transmit Load Balancing ("mode=5") distributes outgoing traffic based on current load, falling back dynamically on link drops.
*   **Why others are incorrect:** 
    - *Option A* uses only one interface.
    - *Option B* requires switch-side LACP.
    - *Option D* requires switch aggregation to prevent out-of-order packet loss.
</details>

---

### Q3: Nginx Gateway Failure
A reverse proxy returns an HTTP "502 Bad Gateway" code. What is the root cause?
*   **A)** The Nginx syntax file is corrupted.
*   **B)** Nginx cannot bind to port 80.
*   **C)** The upstream backend application process is stopped or not listening.
*   **D)** Outbound DNS resolution has timed out.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** A 502 Bad Gateway means Nginx successfully listened to the browser but was rejected when trying to forward packets to the backend port.
</details>

---

### Q4: OpenSSH Nesting Scopes
An administrator appends "PasswordAuthentication no" to the bottom of "sshd_config" after a "Match" block. What happens?
*   **A)** Password logins are disabled globally.
*   **B)** The directive is nested inside the Match block, applying only to matched entities.
*   **C)** SSHD crashes on start.
*   **D)** Global key restrictions take priority.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** A Match block establishes a local context that extends until another Match block or the end of the file is reached.
</details>

---

### Q5: Routing Decision Logic
When evaluating routes, the kernel selects the matching path based on:
*   **A)** The lowest metric.
*   **B)** The longest (most specific) subnet prefix length.
*   **C)** The age of insertion.
*   **D)** Link interface speed.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** The kernel uses the Longest Prefix Match rule. Subnet prefix length takes absolute priority; metrics are only tie-breakers.
</details>

---

### Q6: Host Resolution priority
Which file configures the priority order between checking "/etc/hosts" or network DNS resolvers?
*   **A)** "/etc/resolv.conf"
*   **B)** "/etc/host.conf"
*   **C)** "/etc/nsswitch.conf"
*   **D)** "/etc/networks"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** The "hosts:" line inside "/etc/nsswitch.conf" defines search priority (e.g., "files dns").
</details>

---

### Q7: Software Bridging Endpoint rules
When subordinating "eth1" as a port of bridge "br0", where must you assign any static IP addresses?
*   **A)** On "eth1" directly.
*   **B)** On both "eth1" and "br0".
*   **C)** Directly on "br0" itself.
*   **D)** Bridged ports cannot have IP addresses.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** Member ports act as Layer 2 forwarding lanes; any Layer 3 IP configuration must reside on the logical bridge adapter itself.
</details>

---

### Q8: ss Diagnostics options
Which command option block displays active listening TCP ports along with process names and PIDs?
*   **A)** "ss -tlpn"
*   **B)** "ss -uap"
*   **C)** "ss -s"
*   **D)** "ss -x"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** "-t" TCP, "-l" listening, "-p" processes, and "-n" numeric ports.
</details>

---

### Q9: NTP Stratum progression
Your private local NTP server syncs from a Stratum 2 pool. Your local clients sync from your private NTP server. What stratum do the clients run at?
*   **A)** Stratum 1
*   **B)** Stratum 2
*   **C)** Stratum 3
*   **D)** Stratum 4

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: D**

*   **Why D is correct:** The server operates at Stratum 3 (Stratum 2 + 1 hop). The clients operate at Stratum 4 (Stratum 3 + 1 hop).
</details>

---

### Q10: systemd hostnames
Which hostname type can contain spaces, emojis, and special punctuation?
*   **A)** Static Hostname
*   **B)** Pretty Hostname
*   **C)** Transient Hostname
*   **D)** Localhost Hostname

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** The Pretty Hostname is a free-form UTF-8 metadata string managed by systemd-hostnamed.
</details>

---

### Q11: dig reverse lookups
Which option is the shorthand flag in "dig" to execute an IP-to-Name reverse lookup?
*   **A)** "-r"
*   **B)** "-x"
*   **C)** "+short"
*   **D)** "+reverse"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** "-x" automatically reverses octets and appends ".in-addr.arpa" to query the PTR record.
</details>

---

### Q12: firewalld runtime apply
You added permanent service rules inside firewalld. Which command copies these rules into active runtime memory without dropping connections?
*   **A)** "systemctl restart firewalld"
*   **B)** "firewall-cmd --reload"
*   **C)** "firewall-cmd --runtime-to-permanent"
*   **D)** "nft flush ruleset"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** "--reload" synchronizes active memory from saved disk profiles without breaking active sessions.
</details>

---

### Q13: Public IP Discovery via DNS
Which specialized DNS query safely retrieves your public egress IP, bypassing standard outbound web filters?
*   **A)** "dig +short txt o-o.myaddr.l.google.com @ns1.google.com"
*   **B)** "curl https://ifconfig.me"
*   **C)** "nslookup my-public-ip.com"
*   **D)** "host publicip.net"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** Querying Google's specialized TXT record on UDP port 53 returns the sender's public source IP directly from the DNS packet header.
</details>

---

### Q14: Netplan whitespace rules
Which character is strictly prohibited for indentation inside Netplan YAML profiles?
*   **A)** Space (" ")
*   **B)** Tab ("\t")
*   **C)** Dash ("-")
*   **D)** Colon (":")

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** The YAML standard prohibits tab characters for indentation; you must use spaces.
</details>

---

### Q15: nftables Flush command
Which command removes all active rules, chains, and tables instantly from system RAM?
*   **A)** "nft flush ruleset"
*   **B)** "nft clear all"
*   **C)** "iptables -F"
*   **D)** "systemctl stop nftables"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** "nft flush ruleset" clears the entire in-memory configuration of netfilter immediately.
</details>

---

### Q16: tcpdump output redirection
You want to capture packet headers and write them to a binary PCAP file for offline analysis. Which flag do you append to tcpdump?
*   **A)** "> capture.pcap"
*   **B)** "-w capture.pcap"
*   **C)** "-r capture.pcap"
*   **D)** "--save capture.pcap"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** "-w" writes raw packet data in the binary PCAP format. Redirection (">") writes corrupt plain text.
</details>

---

### Q17: NetworkManager Profile Modification
Which parameter must you set to "manual" inside "nmcli" to stop DHCP from overriding static IPs?
*   **A)** "ipv4.method"
*   **B)** "ipv4.dhcp"
*   **C)** "ipv4.gateway"
*   **D)** "device.dhcp"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** Setting "ipv4.method manual" disables DHCP queries on that logical connection profile.
</details>

---

### Q18: Double-NAT identification
When executing "traceroute -n 8.8.8.8", you see two consecutive hops returning private RFC 1918 addresses before reaching a public gateway. This indicates:
*   **A)** Asymmetric routing.
*   **B)** Double NAT.
*   **C)** Port-binding collision.
*   **D)** Unsynchronized clocks.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Double NAT is verified when a packet transits multiple private subnet routing boundaries before exiting to the ISP gateway.
</details>

---

### Q19: DNS Zone query targets
To query BIND nameserver "192.168.1.100" directly for the MX record of "test.local", bypass local resolving with:
*   **A)** "dig test.local mx @192.168.1.100"
*   **B)** "dig test.local mx server=192.168.1.100"
*   **C)** "nslookup mx test.local -s 192.168.1.100"
*   **D)** "dig -x 192.168.1.100 test.local mx"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: A**

*   **Why A is correct:** The "@" prefix tells dig to direct the DNS query package directly to the targeted IP.
</details>

---

### Q20: Nftables Ordering rules
If you append a general drop rule for port 80 at the top of a chain, and a specific accept rule for host "10.0.0.50" on port 80 below it, what happens to packets from "10.0.0.50"?
*   **A)** They are accepted.
*   **B)** They are dropped.
*   **C)** They are redirected.
*   **D)** The ruleset crashes.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Rules are evaluated from top to bottom. The first match executes its action and terminates chain evaluation. The packet is dropped immediately, and the accept rule is never evaluated.
</details>

---

## Exam Audit & Study Matrix

If you missed any questions, use this study guide to review the specific chapters:

| Question # | Correct Option | Covered Section | Target Study Module |
| :---: | :---: | :--- | :--- |
| **Q1** | B | Section 010: Core Host Config | [M2: Interface IP configurations](sections/section-010/module-02/course.md) |
| **Q2** | C | Section 020: Aggregation & Routing | [M1: Link Aggregation (Bonding)](sections/section-020/module-01/course.md) |
| **Q3** | C | Section 050: Application Proxies | [M1: Nginx Reverse Proxy](sections/section-050/module-01/course.md) |
| **Q4** | B | Section 050: Application Proxies | [M3: OpenSSH Server Hardening](sections/section-050/module-03/course.md) |
| **Q5** | B | Section 020: Aggregation & Routing | [M3: Multi-Interface Static Routing](sections/section-020/module-03/course.md) |
| **Q6** | C | Section 010: Core Host Config | [M4: Local Hostname Resolution](sections/section-010/module-04/course.md) |
| **Q7** | C | Section 020: Aggregation & Routing | [M2: Software Bridging](sections/section-020/module-02/course.md) |
| **Q8** | A | Section 060: Persistence & Diagnostics | [M3: Active Socket Diagnostics (ss)](sections/section-060/module-03/course.md) |
| **Q9** | D | Section 040: Time & Name Services | [M2: NTP Server Mode & Stratums](sections/section-040/module-02/course.md) |
| **Q10** | B | Section 010: Core Host Config | [M2: Static Hostname Management](sections/section-010/module-02/course.md) |
| **Q11** | B | Section 040: Time & Name Services | [M3: DNS Verification with dig](sections/section-040/module-03/course.md) |
| **Q12** | B | Section 030: Firewalls & Filtering | [M2: firewalld Zones and Services](sections/section-030/module-02/course.md) |
| **Q13** | A | Section 010: Core Host Config | [M3: Public IP Discovery Behind NAT](sections/section-010/module-03/course.md) |
| **Q14** | B | Section 060: Persistence & Diagnostics | [M2: Netplan YAML Configurations](sections/section-060/module-02/course.md) |
| **Q15** | A | Section 030: Firewalls & Filtering | [M1: Packet Filtering with nftables](sections/section-030/module-01/course.md) |
| **Q16** | B | Section 060: Persistence & Diagnostics | [M4: Raw Packet Capturing (tcpdump)](sections/section-060/module-04/course.md) |
| **Q17** | A | Section 060: Persistence & Diagnostics | [M1: Persistent Network Managers](sections/section-060/module-01/course.md) |
| **Q18** | B | Section 010: Core Host Config | [M3: Public IP Discovery Behind NAT](sections/section-010/module-03/course.md) |
| **Q19** | A | Section 040: Time & Name Services | [M3: DNS Verification with dig](sections/section-040/module-03/course.md) |
| **Q20** | B | Section 030: Firewalls & Filtering | [M1: Packet Filtering with nftables](sections/section-030/module-01/course.md) |
