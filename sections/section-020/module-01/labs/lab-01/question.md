# Build a persistent active-backup bond

The VM supplies dummy1, dummy2 as disposable dummy interfaces. They let you inspect kernel bond state without moving the management NIC. They do not model physical cable failure.

Estimated learner time: 10–15 minutes, plus VM startup and any reboot. This lab starts independently.

## Tasks

1. Create `bond0` with active-backup mode and members `dummy1` and `dummy2`.
2. Bring `bond0` and its members up; inspect `/proc/net/bonding/bond0` and confirm an active member.
3. Persist this topology in Netplan, reboot, and verify the same state. Leave the management interface unchanged.

<!-- curriculum-links -->
## Related lessons and assessment

Read [section-020/module-01](../../course.md).

The grader checks:

- Confirms bond0 exists in active-backup mode with both dummy1 and dummy2 enslaved.
- Confirms /proc/net/bonding/bond0 reports a Currently Active Slave other than None.
- Check the bond0 Netplan declaration; lifecycle CI also reboots and checks live state.

Inspect your work before submitting. Submission ends this environment.
