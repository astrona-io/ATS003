# Question

Solve this question on: `web-srv1`

A client reports that web-srv1's application on port 8080 is unreachable. You don't yet know whether the process isn't running, isn't listening on the right address, is being blocked by a local firewall rule, or whether packets aren't even arriving. Diagnose the problem methodically — using `ss`, `nft`, and `tcpdump` in that order — identify the root cause, and fix it. (In this scenario, the underlying cause turns out to be an `nftables` rule dropping traffic to port 8080.)
