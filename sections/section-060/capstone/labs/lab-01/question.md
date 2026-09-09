# Question

Solve this question on: `terminal`

## Scenario

This is the Section 060 capstone — one integrated connection-recovery
task, no step-by-step guidance.

A web application (`myapp`, a systemd service) is supposed to be reachable
on TCP port `8080`, but clients time out. The service is running and bound
correctly — the problem is a firewall rule silently dropping the traffic.
Diagnose it and restore reachability.

## Tasks

1. **Confirm the listener.** `myapp` must be listening on port `8080` on a
   remotely reachable address (not `127.0.0.1` only), as shown by
   `sudo ss -tulpn`. (This is already the case — verify it, don't break
   it.)

2. **Remove the block.** Find and delete the `nftables` rule that drops
   traffic to `tcp dport 8080`. `sudo nft list ruleset` must no longer
   contain a `tcp dport 8080 drop` rule.

3. **Prove it works.** `curl http://127.0.0.1:8080/` must return a real HTTP
   status (2xx/3xx) end to end.
