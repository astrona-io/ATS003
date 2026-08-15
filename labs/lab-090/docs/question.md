# Question

Solve this question on: `data-001` (server role) and `app-srv1` (client role)

The data tier (`data-001`, `data-002`, `app-srv1`, `web-srv1`, subnet `192.168.10.0/24`) currently has every host reaching out individually to the public NTP pool. The network team wants to reduce that external dependency: `data-001` should keep syncing itself from the public pool as before, but should also become the internal time source for the rest of `192.168.10.0/24`, so the other hosts don't need direct pool access at all. Configure `data-001`'s chrony to serve the internal subnet, point `app-srv1` at `data-001` instead of the public pool, and verify the resulting stratum relationship end to end.

**Lab environment note:** this lab is two VMs — the server (`data-001`'s role) and the client (`app-srv1`'s role). From the client VM, the server is reachable as `astrona-ats-003-lab-090-server`.
