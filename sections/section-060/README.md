# Section 060: Persistent Configurations & Diagnostics

System modifications configured purely at runtime will disappear upon host reboots. This portal coordinates the conceptual reading, guided training, and unguided challenge sandboxes for NetworkManager nmcli profiles, Netplan YAML files, active socket tracking with ss, and packet capturing with tcpdump.

---

## What You Will Master

By completing this section, you will acquire three core capabilities:
*   **nmcli Profiles**: Persistently add static network connections, gateway nexthops, and custom DNS servers.
*   **Netplan Configuration**: Write structured indentation YAML files and apply them safely using "netplan try".
*   **Forensic Diagnostics**: Capture raw packet dumps, isolate port binding crashes, and diagnose network drops.

---

## The Learning & Lab Path

### 1. Theoretical Concepts & Metaphors
*   **[Module 1: Persistent Network Managers](./module-01/course.md)**
*   **[Module 2: Netplan YAML Configurations](./module-02/course.md)**
*   **[Module 3: Active Socket Diagnostics (ss)](./module-03/course.md)**
*   **[Module 4: Raw Packet Capturing (tcpdump)](./module-04/course.md)**

### 2. Guided Training Labs
*   **Hands-on Training Lab 1 (nmcli):** **[section-060/module-01](../../labs/section-060/module-01/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-060/module-01/lab-01")
*   **Hands-on Training Lab 2 (Netplan):** **[section-060/module-02](../../labs/section-060/module-02/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-060/module-02/lab-01")
*   **Hands-on Training Lab 3 (ss sockets):** **[section-060/module-03](../../labs/section-060/module-03/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-060/module-03/lab-01")
*   **Hands-on Training Lab 4 (tcpdump Sniffing):** **[section-060/module-04](../../labs/section-060/module-04/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-060/module-04/lab-01")

### 3. Unguided Challenge Lab
*   **Hands-on Challenge Lab (Capstone):** **[section-060/capstone](../../labs/section-060/capstone/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-060/capstone/lab-01")

---

## Ready for Assessment?

*   **[Take the Section 060 Knowledge Check Quiz](./quiz.md)**
