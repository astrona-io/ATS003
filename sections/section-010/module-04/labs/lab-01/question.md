# Repair local hostname resolution

The local hosts file maps `app-srv1` to the wrong address. This exercise tests name resolution; the address does not need to be assigned to this VM.

Estimated learner time: 10–15 minutes, plus VM startup and any reboot. This lab starts independently.

## Tasks

1. Inspect `/etc/nsswitch.conf`, `/etc/hosts` and `getent hosts app-srv1`.
2. Correct the mapping so `app-srv1` resolves to `192.168.10.71`, keeping unrelated entries.
3. Verify forward lookup and `getent hosts 192.168.10.71`, then confirm the mapping survives a reboot.

<!-- curriculum-links -->
## Related lessons and assessment

Read [section-010/module-04](../../course.md).

The grader checks:

- Confirms getent hosts app-srv1 resolves to 192.168.10.71.
- Confirms getent hosts 192.168.10.71 resolves back to app-srv1.

Inspect your work before submitting. Submission ends this environment.
