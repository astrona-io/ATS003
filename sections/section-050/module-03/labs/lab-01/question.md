# Question

Solve this question on: `terminal`

## Scenario

`sshd` is running with a deliberately loose baseline:
`PasswordAuthentication yes` and `X11Forwarding yes`, no `Match` blocks.
Two local users exist — `elena` and `victor` — each with a password equal
to their username and no SSH keys. Harden the daemon as follows, without
locking out the key-based admin account.

## Tasks

1. **Disable X11 forwarding globally.** `sshd -T` must report
   `x11forwarding no`.

2. **Password auth: only `elena`.** The effective config must resolve to
   `passwordauthentication yes` for `elena` and `passwordauthentication no`
   for `victor` (check with `sshd -T -C user=<name>,host=<hostname>,addr=127.0.0.1`).
   Use a global `no` plus a `Match User elena` exception.

3. **Login banner for both users.** Create the file `/etc/ssh/sshd-banner`
   (any text), and configure `sshd` so the effective `banner` value for
   both `elena` and `victor` is `/etc/ssh/sshd-banner`.

4. **Working end state.** `sshd`/`ssh` stays active; a real password SSH
   login as `elena` succeeds, and one as `victor` is rejected.
