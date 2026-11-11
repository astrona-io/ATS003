# Routed traffic and masquerade

An application request can fail even when every VM has an address. The router must forward the packet, its firewall must permit the flow, and the server needs a path for the reply. This module uses three VMs to separate those decisions.

[Read the routing lesson](course-01-forward-filter-and-translate.md), then complete the independent [routed NAT lab](labs/lab-01/question.md).

<!-- astrona:playground -->

<!-- curriculum-practice -->
## Practice and assessment

- [Routed NAT and Forward Filtering](labs/lab-01/question.md): Forward permitted requests between two private subnets; Prove source NAT from the destination response; Reject forbidden traffic and survive a router reboot.
