# Section 050: Application Reverse Proxies (Nginx & SSH)

Exposing application runtimes directly to public ingress ports is bad engineering practice. This portal coordinates the conceptual reading, guided training, and unguided challenge sandboxes for Nginx reverse proxying, upstream load-balancing pools, and OpenSSH server access controls.

---

## What You Will Master

By completing this section, you will acquire three core capabilities:
*   **Nginx Routing**: Configure location routing directives and manage path stripping with trailing slashes.
*   **Load Balancing**: Build backend server pools, configure health safeguards, and retry requests on failures.
*   **SSH server Hardening**: Disable weak features globally, set banner notifications, and write conditional user overrides.

---

## The Learning & Lab Path

### 1. Theoretical Concepts & Metaphors
*   **[Module 1: Nginx Reverse Proxy](./module-01/course.md)**
*   **[Module 2: Nginx Load Balancers](./module-02/course.md)**
*   **[Module 3: OpenSSH Server Hardening](./module-03/course.md)**

### 2. Guided Training Labs
*   **Hands-on Training Lab 1 (Nginx Proxy):** **[section-050/module-01](../../labs/section-050/module-01/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-050/module-01/lab-01")
*   **Hands-on Training Lab 2 (Nginx LB):** **[section-050/module-02](../../labs/section-050/module-02/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-050/module-02/lab-01")
*   **Hands-on Training Lab 3 (SSH Hardening):** **[section-050/module-03](../../labs/section-050/module-03/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-050/module-03/lab-01")

### 3. Unguided Challenge Lab
*   **Hands-on Challenge Lab (Capstone):** **[section-050/capstone](../../labs/section-050/capstone/lab-01)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/section-050/capstone/lab-01")

---

## Ready for Assessment?

*   **[Take the Section 050 Knowledge Check Quiz](./quiz.md)**
