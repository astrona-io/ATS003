# Section 030: Network Security & Packet Filtering (Firewalls)

Secure the host at the packet layer: build nftables tables and rulesets from first principles, then manage the same protections through firewalld zones and service abstractions.

## Lessons and practice

Work through the lessons in order. Each exercise starts independently.

1. [Packet Filtering with nftables](module-01/course.md)
2. [firewalld Zones and Services](module-02/course.md)
3. [Routed traffic and masquerade](module-03/course.md)

## Required exercises

- [Packet Filtering with nftables Lab](module-01/labs/lab-01/question.md): Build nftables filter and NAT tables with chains on the right hooks; Drop, redirect and restrict traffic by port and source address; Block outgoing traffic to one host from the output chain.
- [firewalld Zones and Services Lab](module-02/labs/lab-01/question.md): Allow a named service and a port in the public zone; Make each change both live now and saved for the next reload.
- [Routed NAT and Forward Filtering](module-03/labs/lab-01/question.md): Forward permitted requests between two private subnets; Prove source NAT from the destination response; Reject forbidden traffic and survive a router reboot.

Finish the [section knowledge check](quiz.yaml).

See [optional and legacy exercises](../../docs/practice-variants.md) for retained older lab IDs.
