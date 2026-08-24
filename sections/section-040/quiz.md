# Section 040 Knowledge Check: Time & Name Services

Test your NTP server, stratum architectures, and BIND DNS queries with these 5 scenario questions.

---

## Scenario-Based Questions

### Question 1
You run "chronyc sources" on a client node, and the master time server is flagged with a stratum of "16". What does this indicate?
*   **A)** Synchronization is highly precise.
*   **B)** The master server is completely unsynchronized or offline, representing an invalid clock.
*   **C)** The firewall is redirecting the packets.
*   **D)** The master is running in local RTC mode.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Stratum 16 is the standard NTP indicator for an unsynchronized, invalid clock state.
</details>
