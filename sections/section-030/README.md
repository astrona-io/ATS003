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
*   **[Module 1: Packet Filtering with nftables](./module-01/course.md)**
*   **[Module 2: firewalld Zones and Services](./module-02/course.md)**

### 2. Guided Training Labs
*   **Hands-on Training Lab 1 (nftables):** **[lab-031](../../labs/lab-031)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-031")
*   **Hands-on Training Lab 2 (firewalld):** **[lab-032](../../labs/lab-032)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-032")

### 3. Unguided Challenge Lab
*   **Hands-on Challenge Lab (Capstone):** **[lab-030](../../labs/lab-030)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-030")

---

## Ready for Assessment?

*   **[Take the Section 030 Knowledge Check Quiz](./quiz.md)**
