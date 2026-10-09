# Link Aggregation & Routing (Bridges, Bonds & Routes)

Astronaut, this section is about how your ship joins its antennas together and how it chooses a lane for every signal. You team antennas into a **bond** so one failure does not cut you off, plug antennas into a **bridge** so they share one local lane, and draw **static routes** on the ship's star chart so traffic for each network leaves by the right antenna.

## What you will be able to do

By the end of this section you can:

- **Bond interfaces:** build an active-backup bond, read its state, and trigger a failover yourself.
- **Bridge interfaces:** build a software bridge, attach ports, read what it learned, and stop a loop with the Spanning Tree Protocol.
- **Route between networks:** add, check, replace and remove static routes, predict which route Linux picks, and troubleshoot a destination you cannot reach.
- **Make it last:** explain why all of this disappears on reboot when it is built with `ip`, and where it must be written to come back.

## The modules

Each module has its own playground and ends with a graded mission.

1. [Link Aggregation with Linux Bonding](./module-01/course.md): teaming two antennas into one link, bonding modes, and failover.
2. [Software Bridging](./module-02/course.md): a virtual switch inside the kernel, its forwarding database, and loops.
3. [Multi-Interface Static Routing](./module-03/course.md): reading and drawing the star chart, metrics, and a troubleshooting order.

## Check yourself and the capstone

When you have finished the modules:

- Take the [Section 020 knowledge check](./quiz.md), five scenario questions on bonding, bridging and routing.
- Then take on the [section capstone](./capstone/labs/lab-01/README.md): one static routing task between two machines, with no step-by-step help.
