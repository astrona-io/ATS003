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

Each section's labs live under `labs/section-XXX/` — one `lab-01/` per module, plus a `labs/section-XXX/capstone/lab-01/` per section. Copy a path from the table below and run it with the `astrona` CLI:
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c <lab-path>
```

| Section & Domain Portal | Module / Chapter | Dedicated Lab Sandbox | astrona CLI Command |
| :--- | :--- | :--- | :--- |
| **[010: Core Host Config](./sections/section-010/)** | M1: IPv4 & IPv6 Addressing<br>M2: Static Hostname Management<br>M3: Public IP Discovery Behind NAT<br>M4: Local Hostname Name Resolution<br>**Section Capstone Challenge** | [M1 (Practice)](labs/section-010/module-01/lab-01)<br>[M2 (Practice)](labs/section-010/module-02/lab-01)<br>[M3 (Practice)](labs/section-010/module-03/lab-01)<br>[M4 (Practice)](labs/section-010/module-04/lab-01)<br>**[Capstone](labs/section-010/capstone/lab-01)** | `astrona run ... -c labs/section-010/module-01/lab-01`<br>`astrona run ... -c labs/section-010/module-02/lab-01`<br>`astrona run ... -c labs/section-010/module-03/lab-01`<br>`astrona run ... -c labs/section-010/module-04/lab-01`<br>`astrona run ... -c labs/section-010/capstone/lab-01` |
| **[020: Aggregation & Routing](./sections/section-020/)** | M1: Link Aggregation (Bonding)<br>M2: Software Bridging<br>M3: Multi-Interface Static Routing<br>**Section Capstone Challenge** | [M1 (Practice)](labs/section-020/module-01/lab-01)<br>[M2 (Practice)](labs/section-020/module-02/lab-01)<br>[M3 (Practice)](labs/section-020/module-03/lab-01)<br>**[Capstone](labs/section-020/capstone/lab-01)** | `astrona run ... -c labs/section-020/module-01/lab-01`<br>`astrona run ... -c labs/section-020/module-02/lab-01`<br>`astrona run ... -c labs/section-020/module-03/lab-01`<br>`astrona run ... -c labs/section-020/capstone/lab-01` |
| **[030: Firewalls & Filtering](./sections/section-030/)** | M1: Packet Filtering with nftables<br>M2: firewalld Zones and Services<br>**Section Capstone Challenge** | [M1 (Practice)](labs/section-030/module-01/lab-01)<br>[M2 (Practice)](labs/section-030/module-02/lab-01)<br>**[Capstone](labs/section-030/capstone/lab-01)** | `astrona run ... -c labs/section-030/module-01/lab-01`<br>`astrona run ... -c labs/section-030/module-02/lab-01`<br>`astrona run ... -c labs/section-030/capstone/lab-01` |
| **[040: Time & Name Services](./sections/section-040/)** | M1: NTP Client Time Synchronization<br>M2: NTP Server Mode and Stratums<br>M3: DNS Verification with dig<br>**Section Capstone Challenge** | [M1 (Practice)](labs/section-040/module-01/lab-01)<br>[M2 (Practice)](labs/section-040/module-02/lab-01)<br>[M3 (Practice)](labs/section-040/module-03/lab-01)<br>**[Capstone](labs/section-040/capstone/lab-01)** | `astrona run ... -c labs/section-040/module-01/lab-01`<br>`astrona run ... -c labs/section-040/module-02/lab-01`<br>`astrona run ... -c labs/section-040/module-03/lab-01`<br>`astrona run ... -c labs/section-040/capstone/lab-01` |
| **[050: Application Proxies](./sections/section-050/)** | M1: Nginx Reverse Proxy<br>M2: Nginx Upstream Load Balancers<br>M3: OpenSSH Server Hardening<br>**Section Capstone Challenge** | [M1 (Practice)](labs/section-050/module-01/lab-01)<br>[M2 (Practice)](labs/section-050/module-02/lab-01)<br>[M3 (Practice)](labs/section-050/module-03/lab-01)<br>**[Capstone](labs/section-050/capstone/lab-01)** | `astrona run ... -c labs/section-050/module-01/lab-01`<br>`astrona run ... -c labs/section-050/module-02/lab-01`<br>`astrona run ... -c labs/section-050/module-03/lab-01`<br>`astrona run ... -c labs/section-050/capstone/lab-01` |
| **[060: Persistence & Diagnostics](./sections/section-060/)** | M1: Persistent Network Managers<br>M2: Netplan YAML Configurations<br>M3: Active Socket Diagnostics (ss)<br>M4: Raw Packet Capturing (tcpdump)<br>**Section Capstone Challenge** | [M1 (Practice)](labs/section-060/module-01/lab-01)<br>[M2 (Practice)](labs/section-060/module-02/lab-01)<br>[M3 (Practice)](labs/section-060/module-03/lab-01)<br>[M4 (Practice)](labs/section-060/module-04/lab-01)<br>**[Capstone](labs/section-060/capstone/lab-01)** | `astrona run ... -c labs/section-060/module-01/lab-01`<br>`astrona run ... -c labs/section-060/module-02/lab-01`<br>`astrona run ... -c labs/section-060/module-03/lab-01`<br>`astrona run ... -c labs/section-060/module-04/lab-01`<br>`astrona run ... -c labs/section-060/capstone/lab-01` |

---

## Support This Project

ATS003 is free training material. If it helps you, consider supporting ongoing work via [Liberapay](https://liberapay.com/Astrona.io).
