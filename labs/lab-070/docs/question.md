# Question

`astro-ats-003-lab-070` needs two changes for an upcoming container rollout and a NIC-redundancy requirement from the infra team:

1. Create a Linux bridge `br0` that enslaves interface `dummy0`, so containers scheduled on this host can be given direct L2 connectivity to the physical network.
2. Bond interfaces `dummy1` and `dummy2` into `bond0` using active-backup mode, so a single NIC or cable failure doesn't take the host off the network. The switch ports for dummy1/dummy2 are not configured for LACP, so the bonding mode must not depend on switch-side link aggregation.

Both the bridge and the bond must persist across reboots.

`dummy0`, `dummy1`, and `dummy2` are local stand-in interfaces provisioned for this lab — treat them exactly as you would the real extra physical NICs the scenario describes. Do not enslave the host's primary/management interface (the one holding the default route) into either the bridge or the bond.
