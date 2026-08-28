# Linux Foundation Certified System Administrator (LFCS)

[![Liberapay](https://img.shields.io/badge/Liberapay-Support_Astrona.io-F6C915?logo=liberapay&logoColor=black&style=for-the-badge)](https://liberapay.com/Astrona.io)

---

## Networking Domain (25% Exam Weight)

Free reference guide covering all official objectives within the LFCS **Networking** domain.

---

### Official Exam Objectives

* **IP Addressing & Hostname Resolution**
  * Configure static and dynamic IPv4 / IPv6 addresses
  * Manage system hostname and local/remote DNS (`/etc/hosts`, `/etc/resolv.conf`)
* **Time Synchronization**
  * Set and synchronize system time using NTP servers (`chrony`, `systemd-timesyncd`)
* **Network Monitoring & Troubleshooting**
  * Analyze sockets, ports, and traffic (`ip`, `ss`, `netstat`, `traceroute`, `tcpdump`)
* **OpenSSH Server & Client**
  * Configure secure SSH access, key-based authentication, and daemon hardening (`/etc/ssh/sshd_config`)
* **Packet Filtering, NAT & Port Redirection**
  * Manage firewall rules, Network Address Translation (NAT), and port forwarding (`nftables`, `firewalld`, `iptables`)
* **Static Routing**
  * Manage persistent and temporary IP routing tables (`ip route`)
* **Bridge & Bonding Devices**
  * Create network bonds, link aggregation, and virtual bridge interfaces (`nmcli`, `ip link`)
* **Reverse Proxies & Load Balancers**
  * Configure traffic forwarding and load balancing (e.g., NGINX, HAProxy)

---

### Essential Command Reference

```bash
# Network Configuration & Routing
ip addr show                         # View active IP addresses
ip route show                        # View kernel routing table
nmcli connection add type bond ...   # Create a bonded interface

# Monitoring & Time Sync
ss -tulpn                            # List listening ports with PIDs
chronyc tracking                     # Verify NTP time synchronization status

# Firewall & NAT
firewall-cmd --add-forward-port=...  # Configure port redirection (firewalld)
---

## Complete Curriculum & Lab Mapping

To run any of the labs below, copy its path (e.g., `labs/lab-011`) and run it with the `astrona` CLI:
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c <lab-path>
```

| Section & Domain Portal | Module / Chapter | Dedicated Lab Sandbox | astrona CLI Command |
| :--- | :--- | :--- | :--- |
| **[010: Core Host Config](./sections/section-010/)** | M1: IPv4 & IPv6 Addressing<br>M2: Static Hostname Management<br>M3: Public IP Discovery Behind NAT<br>M4: Local Hostname Name Resolution<br>**Section Capstone Challenge** | `lab-011 (Practice)`<br>`lab-012 (Practice)`<br>`lab-013 (Practice)`<br>`lab-014 (Practice)`<br>`lab-010 (Challenge)` | `astrona run ... -c labs/lab-011`<br>`astrona run ... -c labs/lab-012`<br>`astrona run ... -c labs/lab-013`<br>`astrona run ... -c labs/lab-014`<br>`astrona run ... -c labs/lab-010` |
| **[020: Aggregation & Routing](./sections/section-020/)** | M1: Link Aggregation (Bonding)<br>M2: Software Bridging<br>M3: Multi-Interface Static Routing<br>**Section Capstone Challenge** | `lab-021 (Practice)`<br>`lab-022 (Practice)`<br>`lab-023 (Practice)`<br>`lab-020 (Challenge)` | `astrona run ... -c labs/lab-021`<br>`astrona run ... -c labs/lab-022`<br>`astrona run ... -c labs/lab-023`<br>`astrona run ... -c labs/lab-020` |
| **[030: Firewalls & Filtering](./sections/section-030/)** | M1: Packet Filtering with nftables<br>M2: firewalld Zones and Services<br>**Section Capstone Challenge** | `lab-031 (Practice)`<br>`lab-032 (Practice)`<br>`lab-030 (Challenge)` | `astrona run ... -c labs/lab-031`<br>`astrona run ... -c labs/lab-032`<br>`astrona run ... -c labs/lab-030` |
| **[040: Time & Name Services](./sections/section-040/)** | M1: NTP Client Time Synchronization<br>M2: NTP Server Mode and Stratums<br>M3: DNS Verification with dig<br>**Section Capstone Challenge** | `lab-041 (Practice)`<br>`lab-042 (Practice)`<br>`lab-043 (Practice)`<br>`lab-040 (Challenge)` | `astrona run ... -c labs/lab-041`<br>`astrona run ... -c labs/lab-042`<br>`astrona run ... -c labs/lab-043`<br>`astrona run ... -c labs/lab-040` |
| **[050: Application Proxies](./sections/section-050/)** | M1: Nginx Reverse Proxy<br>M2: Nginx Upstream Load Balancers<br>M3: OpenSSH Server Hardening<br>**Section Capstone Challenge** | `lab-051 (Practice)`<br>`lab-052 (Practice)`<br>`lab-053 (Practice)`<br>`lab-050 (Challenge)` | `astrona run ... -c labs/lab-051`<br>`astrona run ... -c labs/lab-052`<br>`astrona run ... -c labs/lab-053`<br>`astrona run ... -c labs/lab-050` |
| **[060: Persistence & Diagnostics](./sections/section-060/)** | M1: Persistent Network Managers<br>M2: Netplan YAML Configurations<br>M3: Active Socket Diagnostics (ss)<br>M4: Raw Packet Capturing (tcpdump)<br>**Section Capstone Challenge** | `lab-061 (Practice)`<br>`lab-062 (Practice)`<br>`lab-063 (Practice)`<br>`lab-064 (Practice)`<br>`lab-060 (Challenge)` | `astrona run ... -c labs/lab-061`<br>`astrona run ... -c labs/lab-062`<br>`astrona run ... -c labs/lab-063`<br>`astrona run ... -c labs/lab-064`<br>`astrona run ... -c labs/lab-060` |

---

## Support This Project

ATS003 is free training material. If it helps you, consider supporting ongoing work via [Liberapay](https://liberapay.com/Astrona.io).
