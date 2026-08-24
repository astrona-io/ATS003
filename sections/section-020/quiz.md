# Section 020 Knowledge Check: Aggregation & Routing

Test your bonding, bridging, and multi-interface routing skills with these 5 scenario questions.

---

## Scenario-Based Questions

### Question 1
You configure a static route "ip route add 172.16.10.0/24 via 10.0.0.1 dev eth1", but the kernel throws "Error: Nexthop has invalid gateway". What is the cause?
*   **A)** Port 10.0.0.1 is firewalled.
*   **B)** Subnet 172.16.10.0 is already mapped.
*   **C)** The gateway IP 10.0.0.1 is not located inside any connected interface subnets.
*   **D)** Metplan has locked the route.

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: C**

*   **Why C is correct:** A gateway router must be directly reachable on the Layer 2 local segment of one of your active interfaces before the kernel can inject it as a valid routing nexthop.
</details>
