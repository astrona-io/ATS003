# Section 010 Knowledge Check: Core Host Configuration

Test your host IP, name resolution, and NAT boundary diagnostics with these 5 scenario questions.

---

## Scenario-Based Questions

### Question 1
You run "ip addr show" on a virtual machine and discover only the address "10.0.0.50" is assigned. Whitelisting rules on an external API require your VM's public IP. Why does the card not show it?
*   **A)** The local network card has dropped.
*   **B)** The server is behind a NAT gateway; the public IP resides on the edge router, not the guest VM card.
*   **C)** The transient hostname is block-overriding it.
*   **D)** IPv6 link-local addresses have taken priority.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** Edge NAT gateways rewrite private RFC 1918 source addresses at the network exit boundary. The local host's operating system only sees and reports its own Layer 3 NIC configuration.
</details>
