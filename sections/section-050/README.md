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
*   **Hands-on Training Lab 1 (Nginx Proxy):** **[lab-051](../../labs/lab-051)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-051")
*   **Hands-on Training Lab 2 (Nginx LB):** **[lab-052](../../labs/lab-052)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-052")
*   **Hands-on Training Lab 3 (SSH Hardening):** **[lab-053](../../labs/lab-053)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-053")

### 3. Unguided Challenge Lab
*   **Hands-on Challenge Lab (Capstone):** **[lab-050](../../labs/lab-050)** (astrona command: "astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-050")

---

## Ready for Assessment?

*   **[Take the Section 050 Knowledge Check Quiz](./quiz.md)**
