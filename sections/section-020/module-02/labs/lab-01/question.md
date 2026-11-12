# Build a persistent software bridge

The VM supplies dummy0 as disposable dummy interfaces. They let you inspect kernel bridge state without moving the management NIC. They do not model physical cable failure.

Estimated learner time: 10–15 minutes, plus VM startup and any reboot. This lab starts independently.

## Tasks

1. Create `br0` with member `dummy0` and STP disabled.
2. Bring `br0` and its members up; inspect `bridge link` and confirm `dummy0` is forwarding.
3. Persist this topology in Netplan, reboot, and verify the same state. Leave the management interface unchanged.

<!-- curriculum-links -->
## Related lessons and assessment

Read [section-020/module-02](../../course.md).

The grader checks:

- Confirms br0 exists, is administratively UP, and dummy0 is enslaved to it.
- Confirms `bridge link show` reports dummy0 as master br0 in forwarding state.
- Check the br0 Netplan declaration; lifecycle CI also reboots and checks live state.

Inspect your work before submitting. Submission ends this environment.
