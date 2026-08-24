# Section 030 Knowledge Check: Packet Filtering

Test your nftables and firewalld administration skills with these 5 scenario questions.

---

## Scenario-Based Questions

### Question 1
What is the direct consequence of adding a permanent rule inside firewalld but forgetting to run "firewall-cmd --reload"?
*   **A)** The rule is written to memory but lost on reboot.
*   **B)** The rule is saved to disk but is completely ignored by the active running ruleset until a reload occurs.
*   **C)** The firewall service stops processing packets.
*   **D)** The interface zone is locked.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Permanent commands write XML rules to disk files under "/etc/firewalld/" but do not modify the active memory ruleset immediately.
</details>
