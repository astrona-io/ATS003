# Section 050 Knowledge Check: Application Proxies

Test your Nginx proxy, upstream load balancing, and OpenSSH hardening skills with these 5 scenario questions.

---

## Scenario-Based Questions

### Question 1
You configure Nginx to load balance app hosts inside an "upstream" block, but client requests are dropped. What is the safest command to verify your configuration files for syntax typos without dropping connections?
*   **A)** "systemctl restart nginx"
*   **B)** "nginx -t"
*   **C)** "nginx -s reload"
*   **D)** "cat /var/log/nginx/error.log"

<details>
<summary><b>Reveal Correct Answer & Teacher's Explanation</b></summary>

**Correct Answer: B**

*   **Why B is correct:** "nginx -t" runs a pre-flight test of configuration files for syntax, braces, or bracket mismatch without interrupting running services.
</details>
