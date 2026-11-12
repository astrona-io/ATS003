# Question

Solve this question on: `terminal`

## Scenario

Astronaut, before the network team files a firewall change request, they need two addresses for this machine. One is the private address it carries on its own interface. The other is the public address the outside world sees after NAT (network address translation, the relay station that swaps the private call sign for a public one). Record both where the audit script expects them.

## Tasks

1. **Private address.** Find this machine's private IPv4 address: the RFC 1918 address bound to its network interface (it starts with `10.`, `172.16.` to `172.31.`, or `192.168.`). Write just the address, with no prefix length and no extra text, to:

   ```
   /opt/course/private_ip
   ```

2. **Public address.** Find this machine's public IPv4 address as the internet sees it. Use an outside HTTP or DNS lookup service; `curl` and `dig` are installed. Write just that address to:

   ```
   /opt/course/public_ip
   ```
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-03](../../course.md).

The grader checks:

- Confirms /opt/course/private_ip holds an RFC1918 address that is actually bound to a local interface.
- Confirms /opt/course/public_ip matches a fresh HTTPS IPv4 lookup from this VM; unavailable lookups are infrastructure failures.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.

Record the public IPv4 address observed from inside this VM. Validation compares it with a fresh HTTPS lookup from the same VM. If its egress changes, repeat the lookup; a public-looking address from another machine is insufficient. An unavailable lookup is an infrastructure error, not a successful grade.
