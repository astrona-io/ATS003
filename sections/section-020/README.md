# Section 020: Link Aggregation & Routing (Bridges, Bonds & Routes)

Build redundant and interconnected links: bond interfaces for uplink aggregation, switch traffic locally with software bridges, and forward packets with multi-interface static routing.

## Lessons and practice

Work through the lessons in order. Each exercise starts independently.

1. [Link Aggregation with Linux Bonding](module-01/course.md)
2. [Software Bridging](module-02/course.md)
3. [Multi-Interface Static Routing](module-03/course.md)

## Required exercises

- [Build a persistent active-backup bond](module-01/labs/lab-01/question.md): Create bond0 using only the supplied practice interfaces; Check active-backup mode and the active member; Persist bond0 in Netplan and verify it after reboot.
- [Build a persistent software bridge](module-02/labs/lab-01/question.md): Create br0 using only the supplied practice interfaces; Check bridge membership and forwarding state; Persist br0 in Netplan and verify it after reboot.
- [Multi-Interface Static Routing Lab](module-03/labs/lab-01/question.md): Add a static route to a partner subnet through a gateway; Prove the route with ip route get and a real ping; Make the route survive a reboot in on-disk configuration.

Finish the [section knowledge check](quiz.yaml).

See [optional and legacy exercises](../../docs/practice-variants.md) for retained older lab IDs.
