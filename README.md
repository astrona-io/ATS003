# ATS003 - LFCS: Networking

[![Liberapay](https://img.shields.io/badge/Liberapay-Support_Astrona.io-F6C915?logo=liberapay&logoColor=black&style=for-the-badge)](https://liberapay.com/Astrona.io)

Free LFCS (Linux Foundation Certified System Administrator) training material,
covering the **Networking** domain (25% of exam weight).

Each module maps to one exam competency and ships with:

- `sections/section-XXX/course.md` — reading material
- `labs/lab-XXX/` — hands-on lab
- `labs/lab-XXX/docs/question.md` + `solution.md` — practice question and walkthrough

## Lab Reference List

| Lab | Title | VMs | Run |
|-----|-------|:---:|-----|
| [lab-010](labs/lab-010) | NTP Time Synchronization with chrony | 1 | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-010` |
| [lab-020](labs/lab-020) | Packet Filtering, Port Redirection, and NAT with nftables | 1 | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-020` |
| [lab-030](labs/lab-030) | Reverse Proxy and Load Balancer with Nginx | 1 | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-030` |
| [lab-040](labs/lab-040) | OpenSSH Server Hardening with Match Blocks | 1 | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-040` |
| [lab-050](labs/lab-050) | IPv4/IPv6 Addressing and Hostname Resolution | 1 | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-050` |
| [lab-060](labs/lab-060) | Static Routing Across Multiple Interfaces | 2 (`target` + `gateway`) | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-060` |
| [lab-070](labs/lab-070) | Bridge and Bonding Interfaces | 1 | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-070` |
| [lab-080](labs/lab-080) | Network Troubleshooting with ss and tcpdump | 1 | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-080` |
| [lab-090](labs/lab-090) | NTP Server Mode and Stratum | 2 (`server` + `client`) | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-090` |
| [lab-100](labs/lab-100) | Static Hostname Configuration | 1 | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-100` |
| [lab-110](labs/lab-110) | DNS Verification with dig | 2 (`client` + `dns`) | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-110` |
| [lab-120](labs/lab-120) | firewalld Zones and Services | 1 | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-120` |
| [lab-130](labs/lab-130) | Determining Your Real (Public) IP Address Behind NAT | 1 | `astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-130` |

## Support This Project

ATS003 is free LFCS training material. If it helped you, consider supporting
ongoing work via [Liberapay](https://liberapay.com/Astrona.io).