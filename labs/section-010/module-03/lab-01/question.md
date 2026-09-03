# Question

Solve this question on: `terminal`

## Scenario

Before filing a firewall change request, the network team needs to know two
addresses for this host: the private address it carries on its own interface,
and the public address the outside world sees it as after NAT. Record both
where the audit script expects them.

## Tasks

1. **Private address.** Find this host's private IPv4 address — the RFC1918
   address bound to its network interface (starts with `10.`, `172.16`–
   `172.31.`, or `192.168.`). Write just the address, with no prefix and no
   extra text, to:

   ```
   /opt/course/private_ip
   ```

2. **Public address.** Find this host's public IPv4 address as seen from the
   internet (use an outside HTTP or DNS lookup service — `curl` and `dig` are
   installed). Write just that address to:

   ```
   /opt/course/public_ip
   ```
