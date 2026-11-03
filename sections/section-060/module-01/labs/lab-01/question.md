# Question

Solve this question on: `terminal`

## Scenario

Before the network team files a firewall change request, they need two
addresses for this host. The first is the private address it carries on its
own network interface. The second is the public address the outside world
sees after NAT (network address translation: a relay station that swaps the
host's private address for its own public one). Record both where the audit
script expects them.

## Tasks

1. **Private address.** Find this host's private IPv4 address. It is the
   address from the private ranges (RFC 1918) that is bound to its network
   interface, so it starts with `10.`, `172.16`–`172.31.`, or `192.168.`.
   Write just the address, with no prefix and no extra text, to:

   ```
   /opt/course/private_ip
   ```

2. **Public address.** Find this host's public IPv4 address as the internet
   sees it. Use an outside HTTP or DNS lookup service; `curl` and `dig` are
   installed. Write just that address to:

   ```
   /opt/course/public_ip
   ```
