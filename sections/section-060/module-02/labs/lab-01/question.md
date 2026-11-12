# Repair merged Netplan configuration

The disposable `np0` interface has two IPv4 addresses. An extra YAML file adds an unintended address to its base configuration. The management interface must keep its existing settings.

Estimated learner time: 10–15 minutes, plus VM startup and any reboot. This lab starts independently.

## Tasks

1. Compare `ip -br address show np0` with `sudo netplan get ethernets.np0` and inspect the files in `/etc/netplan`.
2. Keep only `192.168.130.50/24` in the merged `np0` configuration, with DHCP disabled and the `networkd` renderer. Remove or disable the unintended address declaration; a runtime `ip address del` alone is insufficient.
3. Generate and apply the configuration. Verify that `192.168.130.60/24` is gone.
4. Reboot and confirm the sole intended address returns without changing the management route.

<!-- curriculum-links -->
## Related lessons and assessment

Read [section-060/module-02](../../course.md).

The grader checks:

- Check the merged Netplan address list and renderer.
- Check the active address list and preserve the management default route.

Inspect your work before submitting. Submission ends this environment.
