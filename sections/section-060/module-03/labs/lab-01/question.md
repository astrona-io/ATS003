# Question

Solve this question on: `terminal`

## Scenario

A web application (`myapp`, a systemd service) should be reachable on TCP
port `8080`, but clients time out. The service is running and bound
correctly. The problem is a firewall rule that silently drops the traffic.
Find the cause and make the service reachable again.

## Tasks

1. **Confirm the listener.** `myapp` must be listening on port `8080` on an
   address other machines can reach (not `127.0.0.1` only), as shown by
   `sudo ss -tulpn`. This is already the case: check it, and do not break
   it.

2. **Remove the block.** Find and delete the `nftables` rule that drops
   traffic to `tcp dport 8080`. `sudo nft list ruleset` must no longer
   contain a `tcp dport 8080 drop` rule.

3. **Prove it works.** `curl http://127.0.0.1:8080/` must return a real HTTP
   status (2xx or 3xx) end to end.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-03](../../course.md).

The grader checks:

- Confirms something is listening on TCP port 8080 on a remotely reachable address (via 'ss -tulpn').
- Confirms the 'tcp dport 8080 drop' rule has been removed from the live nftables ruleset.
- Confirms the port 8080 web application responds with a real HTTP status code end to end.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
