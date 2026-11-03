# Question

Solve this question on: `terminal`

## Scenario

Astronaut, the web service `portal` (a systemd service) should answer at `http://portal.lab:8443/`, but every request fails. The service itself is healthy and must not be changed. The fault is somewhere on the way: more than one rung of the ladder is broken. Work from the bottom up, and fix every fault you find.

Do not touch the management interface that carries your own session.

## Tasks

1. **Find and fix the faults.** The practice antenna `lab0` must be up and keep its address `10.66.0.10/24`. The name `portal.lab` must resolve to `10.66.0.10` (check it with `getent hosts portal.lab`). No `nftables` rule may drop `tcp dport 8443`.

2. **Prove it works.** `curl http://portal.lab:8443/` must return a real HTTP status (2xx or 3xx).

3. **Leave the service alone.** `portal.service` must still be running.

The grader checks `lab0` with `ip`, the name with `getent`, the live ruleset with `nft list ruleset`, and a real `curl` request.
