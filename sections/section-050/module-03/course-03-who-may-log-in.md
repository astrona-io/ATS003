# Who May Log In

Astronaut, with passwords gone, the next question is who may even try the airlock. In this part you give the guard a crew list, and then limit how much a single visitor can try before the guard closes the door.

## Restricting who may log in

By default every account on the machine can try to log in over SSH (Secure Shell). `AllowUsers` or `AllowGroups` turns that into a crew list for the airlock.

### Allow lists beat deny lists

If `AllowUsers` or `AllowGroups` is present, **only** the listed users or groups may log in. Everyone else is refused before the password or key is even checked.

Prefer an allow list to `DenyUsers` or `DenyGroups`. A deny list only stops the accounts you thought to name. It misses `postgres`, `jenkins`, or tomorrow's new service account.

### Only `sshusers` may log in

`alice` is in the group `sshusers`, and `bob` is not. Add this line to `/etc/ssh/sshd_test.conf` (or use `AllowUsers alice` instead):

<!-- astrona:playground:renew -->

```text
AllowGroups sshusers
```

Apply it:

```sh
sudo sshd -t -f /etc/ssh/sshd_test.conf && sudo systemctl reload sshd-test
```

Then check the result for both users:

```sh
ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/alice/.ssh/id_ed25519 alice@localhost true; echo "alice: $?"
ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=password bob@localhost true; echo "bob: $?"
```

`alice` gets in, and `bob` is refused whatever he tries:

```text
alice: 0
bob@localhost: Permission denied (publickey,password).
bob: 255
```

`sudo journalctl -u sshd-test` shows the reason in the log: `User bob from 127.0.0.1 not allowed because none of user's groups are listed in AllowGroups`.

## Shrinking the attack surface

Beyond who may log in, a few limits reduce what an attacker, or a bug, can do in one connection. Each one is a single line in the configuration.

### The limits

- `MaxAuthTries 3` sets the failed attempts before the connection is dropped (the default is 6).
- `LoginGraceTime 20` sets the seconds a visitor has to log in before the guard disconnects (the default is 120).
- `MaxStartups 10:30:100` starts refusing new connections that have not logged in yet once 10 are waiting.
- `X11Forwarding no`, `AllowTcpForwarding no` and `AllowAgentForwarding no` turn off forwarding features unless a real workflow needs them. They are paths an attacker can use to move on from a captured session.
- `ClientAliveInterval 300` and `ClientAliveCountMax 2` drop idle sessions.

### The per-connection attempt limit

Set this line in `/etc/ssh/sshd_test.conf`:

```text
MaxAuthTries 2
```

Apply it:

```sh
sudo sshd -t -f /etc/ssh/sshd_test.conf && sudo systemctl reload sshd-test
```

Then connect as `bob` and type wrong passwords:

```sh
ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=password -o NumberOfPasswordPrompts=6 bob@localhost
```

The server cuts the connection after the second wrong password:

```text
Permission denied, please try again.
Permission denied, please try again.
Received disconnect from 127.0.0.1 port 2222:2: Too many authentication failures
```

A scanner that would have tried dozens of passwords per connection now gets two. To also cap the number of *connections* per minute, combine this with a rate limiter at the firewall.

## Common pitfalls

> [!WARNING]
> - **`AllowUsers` without your own account.** If the allow list leaves out the administrator account, nobody can log in. Include yourself, and keep a session open when you reload.
> - **`DenyUsers` as the main control.** A deny list misses accounts you did not name. Use `AllowUsers` or `AllowGroups`.
> - **Leaving forwarding on by habit.** X11, TCP and agent forwarding are paths out of a captured session. Turn them off unless someone needs them.
