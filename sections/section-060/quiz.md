# Section 060 Knowledge Check: Persistence & Diagnostics

Test your persistent Netplan profiles, NetworkManager CLI, and socket forensics ss/tcpdump skills with these 5 scenario questions.

---

## Scenario-Based Questions

### Question 1
You run "tcpdump -i eth0 -n" but the screen scroll-locks with SSH traffic. How do you exclude SSH packets on port 22 from the capture display?
*   **A)** "tcpdump -i eth0 -n block port 22"
*   **B)** "tcpdump -i eth0 -n not port 22"
*   **C)** "tcpdump -i eth0 -n exclude port 22"
*   **D)** "tcpdump -i eth0 -n port !22"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Prepending the "not" operator to a match directive (e.g., "not port 22") excludes matching packets from the capture ruleset.
</details>
