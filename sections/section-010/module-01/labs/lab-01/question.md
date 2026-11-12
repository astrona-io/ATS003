# IPv4 and IPv6 addressing

The management interface already has DHCP connectivity. Add the two application addresses to that interface without replacing its management address.

Estimated learner time: 10–15 minutes, plus VM startup and any reboot. This lab starts independently.

## Tasks

1. Add `192.168.10.71/24` and `fd00:10::70/64` to the management interface.
2. Persist both addresses while keeping management DHCP enabled.
3. Verify the addresses with `ip`, test the local IPv6 address with `ping -6`, then reboot and check again.

<!-- curriculum-links -->
## Related lessons and assessment

Read [section-010/module-01](../../course.md).

The grader checks:

- Confirms the secondary IPv4 address 192.168.10.71/24 is live on the primary interface alongside the original address.
- Confirms the static IPv6 ULA fd00:10::70/64 is bound to the primary interface with global scope.
- Confirms fd00:10::70 actually answers a ping, not just appears in `ip addr`.
- Confirms the secondary IPv4/IPv6 addresses are declared in a persistent Netplan or NetworkManager config, not only applied live.

Inspect your work before submitting. Submission ends this environment.
