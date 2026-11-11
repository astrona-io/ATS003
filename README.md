# Linux Foundation Certified System Administrator (LFCS)

[![Liberapay](https://img.shields.io/badge/Liberapay-Support_Astrona.io-F6C915?logo=liberapay&logoColor=black&style=for-the-badge)](https://liberapay.com/Astrona.io)

---

## Networking Domain (25% Exam Weight)

Free reference guide covering all official objectives within the LFCS **Networking** domain.

---

### Official Exam Objectives

* **IP Addressing & Hostname Resolution**
  * Configure static and dynamic IPv4 / IPv6 addresses, including DHCP clients and lease overrides
  * Manage system hostname and local/remote DNS (`/etc/hosts`, `/etc/nsswitch.conf`, `systemd-resolved`, `resolvectl`)
* **Time Synchronization**
  * Set and synchronize system time using NTP servers (`chrony`, `systemd-timesyncd`)
* **Network Monitoring & Troubleshooting**
  * Analyze sockets, ports, and traffic (`ip`, `ss`, `netstat`, `ping`, `traceroute`, `mtr`, `tcpdump`)
* **OpenSSH Server & Client**
  * Configure secure SSH access, key-based authentication, `~/.ssh/config`, tunnels, and daemon hardening (`/etc/ssh/sshd_config`)
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
```

---

## Complete Curriculum & Lab Mapping

The ordered course is defined in `astrona.yaml`. Each module has focused practice; the addressing and proxy sections also have integration exercises. Section 060 ends with the multi-fault troubleshooting capstone. [Legacy exercises](docs/practice-variants.md) remain available by their existing paths.

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c <lab-path>
```

| Section | Main learning path |
| --- | --- |
| Section 010: Core Host Configuration (Addressing & Hostnames) | [IPv4 and IPv6 addressing](sections/section-010/module-01/labs/lab-01)<br>[Static Hostname Management Lab](sections/section-010/module-02/labs/lab-01)<br>[Public IP Discovery Behind NAT Lab](sections/section-010/module-03/labs/lab-01)<br>[Repair local hostname resolution](sections/section-010/module-04/labs/lab-01)<br>[DHCP Client Lab](sections/section-010/module-05/labs/lab-01)<br>[Addressing and local resolution integration](sections/section-010/capstone/labs/lab-01) |
| Section 020: Link Aggregation & Routing (Bridges, Bonds & Routes) | [Build a persistent active-backup bond](sections/section-020/module-01/labs/lab-01)<br>[Build a persistent software bridge](sections/section-020/module-02/labs/lab-01)<br>[Multi-Interface Static Routing Lab](sections/section-020/module-03/labs/lab-01) |
| Section 030: Network Security & Packet Filtering (Firewalls) | [Packet Filtering with nftables Lab](sections/section-030/module-01/labs/lab-01)<br>[firewalld Zones and Services Lab](sections/section-030/module-02/labs/lab-01)<br>[Routed NAT and Forward Filtering](sections/section-030/module-03/labs/lab-01) |
| Section 040: Time & Domain Name Services (NTP & DNS) | [NTP Client Time Synchronization Lab](sections/section-040/module-01/labs/lab-01)<br>[NTP Server Mode and Stratums Lab](sections/section-040/module-02/labs/lab-01)<br>[DNS Verification with dig Lab](sections/section-040/module-03/labs/lab-01)<br>[DNS Client Resolution Lab](sections/section-040/module-04/labs/lab-01) |
| Section 050: Application Reverse Proxies (Nginx & SSH) | [Reverse proxy to a fixed backend path](sections/section-050/module-01/labs/lab-01)<br>[Balance requests across two upstreams](sections/section-050/module-02/labs/lab-01)<br>[OpenSSH Server Hardening Lab](sections/section-050/module-03/labs/lab-01)<br>[OpenSSH Client Lab](sections/section-050/module-04/labs/lab-01)<br>[Reverse proxy and load balancing integration](sections/section-050/capstone/labs/lab-01) |
| Section 060: Persistent Configurations & Diagnostics | [Repair a persistent NetworkManager profile](sections/section-060/module-01/labs/lab-01)<br>[Repair merged Netplan configuration](sections/section-060/module-02/labs/lab-01)<br>[Active Socket Diagnostics (ss) Lab](sections/section-060/module-03/labs/lab-01)<br>[Capture and decode an HTTP conversation](sections/section-060/module-04/labs/lab-01)<br>[Network troubleshooting capstone](sections/section-060/module-05/labs/lab-01) |

---

## Support This Project

ATS003 is free training material. If it helps you, consider supporting ongoing work via [Liberapay](https://liberapay.com/Astrona.io).

<!-- validation-links -->
## Coverage, testing and releases

See the [lesson and lab coverage map](docs/coverage.md), [validation and OCI release guide](docs/validation-and-releases.md), and [authoring guidance](docs/authoring.md). The coverage map lists every registered lab; CI also discovers every playground.
