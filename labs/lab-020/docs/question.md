# Question

Server `data-001` has two network interfaces: eth0 on 192.168.10.0/24 (the data-tier subnet) and eth1 on 10.10.20.0/24 (a backend link to a partner network).

Traffic destined for the partner subnet 10.10.30.0/24 must be routed via gateway 10.10.20.1 reachable on eth1. This route must persist across reboots.
