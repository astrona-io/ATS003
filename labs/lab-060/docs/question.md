# Question

Server `data-001` has two network interfaces: eth0 on 192.168.10.0/24 (the data-tier subnet) and eth1 on 10.10.20.0/24 (a backend link to a partner network).

Traffic destined for the partner subnet 10.10.30.0/24 must be routed via gateway 10.10.20.1 reachable on eth1. This route must persist across reboots.

**Lab environment note:** this lab is two VMs — the target host (`data-001`'s role) and the gateway fronting the partner subnet `10.10.30.0/24`. This target VM has one real network interface; add the route via the gateway VM, reachable as `astrona-ats-003-lab-060-gateway`. Resolve its address first (`getent hosts astrona-ats-003-lab-060-gateway`), then route through it — the `eth1`/`10.10.20.1` naming in the scenario above is exam-style flavor, not literal to this environment.
