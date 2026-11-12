# Question

Solve this question on: `terminal`

## Scenario

Astronaut, the airlock guard of this training ship, `sshd` (the OpenSSH server), runs with loose standing orders on purpose: `PasswordAuthentication yes` and `X11Forwarding yes`, and no `Match` blocks. Two local users exist, `elena` and `victor`. Each one has a password equal to their user name, and neither has an SSH key.

Harden `sshd` as described below. Do not lock out the administrator account you are using: it logs in with a key.

## Tasks

1. **Turn off X11 forwarding for everyone.** `sudo sshd -T` must report `x11forwarding no`.

2. **Password login for `elena` only.** The effective configuration must resolve to `passwordauthentication yes` for `elena` and `passwordauthentication no` for `victor`. Check it with `sudo sshd -T -C user=<name>,host=<hostname>,addr=127.0.0.1`. Use a global `no` plus a `Match User elena` exception.

3. **A login banner for both users.** Create the file `/etc/ssh/sshd-banner` (any text). Configure `sshd` so that the effective `banner` value for both `elena` and `victor` is `/etc/ssh/sshd-banner`.

4. **A working end state.** The `ssh` service (or `sshd`) stays active. A real password login over SSH as `elena` succeeds, and one as `victor` is rejected.

The grader reads the effective values with `sshd -T` and `sshd -T -C`, and tries real password logins as `elena` and `victor` on `localhost`.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-03](../../course.md).

The grader checks:

- Confirms the sshd/ssh service is active.
- Confirms X11Forwarding is disabled in the effective sshd config (sshd -T).
- Confirms PasswordAuthentication resolves to yes for elena and no for victor via sshd -T -C.
- Confirms Banner resolves to /etc/ssh/sshd-banner for elena and victor via sshd -T -C, and the file exists.
- Confirms real SSH login behavior: elena authenticates with a password, victor is rejected.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
