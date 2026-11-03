# Match Blocks And Safe Reloads

Astronaut, strict rules for the whole crew sometimes need one exception: one crew member who may still use a password, or one address that gets different treatment. A `Match` block is that exception in the airlock guard's standing orders. This part shows how to write one, prove it works, and catch a broken file before it reaches the running guard.

## `Match` blocks: exceptions to the rules

A `Match` block applies its settings **only** when its conditions match the connection: a user, a group, an address, or a local port. Where the block sits in the file matters a lot.

### Where a `Match` block ends

Everything from a `Match` line to the next `Match` line, or to the end of the file, is inside that block. That is why `Match` blocks go at the **bottom**. A `Match` block above normal settings would swallow them all, and they would quietly become exceptions too.

```text
Match User bob
    PasswordAuthentication yes
    X11Forwarding no
```

Only some keywords are allowed inside `Match`, mostly login and session options. A `Match` block *does* override a global setting, whatever their order. So the pattern "deny for everyone, allow for one case" works.

### Password login for `bob` only

Keep `PasswordAuthentication no` as the global setting. Append the `Match User bob` block above to the bottom of `/etc/ssh/sshd_test.conf`:

<!-- astrona:playground:renew -->

```text
Match User bob
    PasswordAuthentication yes
    X11Forwarding no
```

Apply it:

```sh
sudo sshd -t -f /etc/ssh/sshd_test.conf && sudo systemctl reload sshd-test
```

Then check the resolved value for each user with `sshd -T -C`:

```sh
sudo sshd -T -f /etc/ssh/sshd_test.conf -C user=bob,host=localhost,addr=127.0.0.1   | grep '^passwordauthentication '
sudo sshd -T -f /etc/ssh/sshd_test.conf -C user=alice,host=localhost,addr=127.0.0.1 | grep '^passwordauthentication '
```

The setting differs by user:

```text
passwordauthentication yes
passwordauthentication no
```

`sshd -T -C` works the configuration out *as if* for that connection, with `Match` blocks and all. It is the way to test a `Match` block without really connecting. `bob` keeps password login, and everyone else does not.

## Checking before you reload

`sshd -t` reads the configuration and reports errors without touching the running service. Run it **every time**, before every reload. A syntax error that reaches `systemctl restart` can leave you with a service that will not start.

### A broken file caught before it ships

Add a bad line to `/etc/ssh/sshd_test.conf`, for example:

```text
PermitRootLogin maybe
```

Then test the file:

```sh
sudo sshd -t -f /etc/ssh/sshd_test.conf ; echo "exit: $?"
```

You get a specific complaint and a non-zero exit code:

```text
/etc/ssh/sshd_test.conf: line 21: Bad yes/no/prohibit-password/... argument: maybe
exit: 255
```

(Shortened: the list of allowed values is cut. Your line number may differ.)

`sshd-test.service` also runs `sshd -t` before it starts (`ExecStartPre`), so a broken file makes the reload fail loudly instead of taking the service down. On a real server, a passing `sshd -t` plus a second SSH session that is already open is what makes a reload safe. Remove the bad line afterwards.

> [!TIP]
> Before you reload `sshd` on a real server, open a second SSH session and leave it open. If the reload locks out new logins, the open session is still your way back in.

## Common pitfalls

> [!WARNING]
> - **A `Match` block that is not at the bottom.** It captures every line until the next `Match` or the end of the file. Global settings placed after it silently become exceptions.
> - **A `Match` block with nothing under it.** `sshd -t` reports it. Every `Match` line needs at least one indented setting.
> - **Reloading without `sshd -t`.** A syntax error that reaches a restart can stop the service entirely. Test first, every time.
> - **A new `Port` but the old firewall.** Changing `Port` needs a matching firewall rule, and on SELinux systems also `semanage port -a`.

## Your mission: OpenSSH Server Hardening Lab

You can now read the effective configuration, turn off password login, and give one user an exception with a `Match` block. The mission asks you to harden the real `sshd` on a training ship: no X11 forwarding, password login only for one user, and a login banner for both users, proved with `sshd -T -C` and real logins.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ssh-hardening-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-03/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/module-03/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-053
astrona start ssh-hardening-playground
```
