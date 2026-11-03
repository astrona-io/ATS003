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
