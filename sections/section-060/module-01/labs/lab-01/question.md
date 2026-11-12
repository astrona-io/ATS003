# Repair a persistent NetworkManager profile

NetworkManager manages only the disposable `nm0` interface. Its saved `lab-static` profile has the wrong address and does not autoconnect. The management NIC belongs to the existing network service.

Estimated learner time: 10–15 minutes, plus VM startup and any reboot. This lab starts independently.

## Tasks

1. Compare `nmcli connection show lab-static`, active connections and `ip -br address show nm0`.
2. Repair the existing persistent profile: manual IPv4 `192.168.120.50/24`, autoconnect enabled and `ipv4.never-default yes`.
3. Activate the corrected profile and verify that the old `192.168.120.99/24` address is gone.
4. Reboot and confirm `lab-static` is active again. Keep the management interface and default route unchanged.

<!-- curriculum-links -->
## Related lessons and assessment

Read [section-060/module-01](../../course.md).

The grader checks:

- Check the saved NetworkManager address, interface, autoconnect and default-route policy.
- Check the active address and profile without changing management routing.

Inspect your work before submitting. Submission ends this environment.
