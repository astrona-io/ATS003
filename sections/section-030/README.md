# Section 030: Network Security & Packet Filtering (Firewalls)

Host-level packet security is a critical administration responsibility. This portal coordinates the conceptual reading, guided training, and unguided challenge sandboxes for nftables hierarchy, ruleset filters, firewalld zones, and service abstractions.

---

## What You Will Master

By completing this section, you will acquire three core capabilities:
*   **Nftables Ruleset Architecture**: Build custom IPv4 packet-filtering tables and base ingress chains.
*   **Service & Port Overrides**: Deny targeted port queries and enforce workstation-only source access controls.
*   **Firewalld Zones Segmentation**: Bind system adapters to logical trust zones (public, internal, dmz) and reload states dynamically.

---

## The Learning & Lab Path

### 1. Theoretical Concepts & Metaphors

Each module has a short landing page and a set of ordered deep-dive parts. Read the landing page first, then the parts in order.

*   **[Module 1: Packet Filtering with nftables](./module-01/course.md)**
    1.  [Netfilter and the packet path](./module-01/course-01-netfilter-and-packet-flow.md)
    2.  [Tables and address families](./module-01/course-02-tables-and-families.md)
    3.  [Chains, hooks, priority, and policy](./module-01/course-03-chains-hooks-priority.md)
    4.  [Rules: matches and verdicts](./module-01/course-04-rules-matches-verdicts.md)
    5.  [Connection tracking, sets, and maps](./module-01/course-05-conntrack-sets-maps.md)
    6.  [Persistence and operating a ruleset](./module-01/course-06-persistence-and-operations.md)
*   **[Module 2: firewalld Zones and Services](./module-02/course.md)**
    1.  [Architecture and the nftables backend](./module-02/course-01-architecture-and-backends.md)
    2.  [Zones](./module-02/course-02-zones.md)
    3.  [Services, ports, and rich rules](./module-02/course-03-services-ports-richrules.md)
    4.  [Runtime, permanent, and operations](./module-02/course-04-runtime-permanent-operations.md)

### 2. Guided Training Labs
*   **Hands-on Training Lab 1 (nftables):** **[section-030/module-01](../../labs/section-030/module-01/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-030/module-01/lab-01")
*   **Hands-on Training Lab 2 (firewalld):** **[section-030/module-02](../../labs/section-030/module-02/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-030/module-02/lab-01")

### 3. Unguided Challenge Lab
*   **Hands-on Challenge Lab (Capstone):** **[section-030/capstone](../../labs/section-030/capstone/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-030/capstone/lab-01")

---

## Ready for Assessment?

*   **[Take the Section 030 Knowledge Check Quiz](./quiz.md)**
