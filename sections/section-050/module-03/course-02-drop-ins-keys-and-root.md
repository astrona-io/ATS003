# Drop-Ins, Keys And Root

Astronaut, the airlock guard reads its standing orders from top to bottom and keeps the first answer it finds for each order. This part shows why that matters on Ubuntu, and then makes the two changes with the biggest effect: no more passwords, and no more root login.

## First value wins, and the drop-in directory

Two rules decide which value `sshd` uses for a keyword. Together they explain why an edit to the main file sometimes does nothing at all.

### The two rules

1. **The first value found for a keyword wins.** A second `PasswordAuthentication` line later in the file is ignored.
2. **`Include` is read where it appears.** On Debian and Ubuntu, `/etc/ssh/sshd_config` starts with `Include /etc/ssh/sshd_config.d/*.conf`. So any setting in a drop-in file is found *first*, and beats the same setting written later in the main file.

### What this means on Ubuntu

On a stock Ubuntu machine, editing `PasswordAuthentication` in `/etc/ssh/sshd_config` can do **nothing**, because a file in `sshd_config.d/` already set it. Put your changes in a drop-in file of your own, such as `/etc/ssh/sshd_config.d/10-hardening.conf`, or check with `sshd -T` that they really land.

The playground's `sshd_test.conf` does *not* `Include` anything on purpose, so it stays predictable.

## Forcing keys and locking out root

The two lines with the biggest effect turn off password login and root login. You set them first, then prove that key login still works.

### The two lines

```text
PasswordAuthentication no
PermitRootLogin no
```

`PermitRootLogin` also takes `prohibit-password`, which still lets root log in with a key. Use `no` if root should never log in over SSH (Secure Shell) at all.

Before you turn passwords off on a real server, **confirm that key login already works** for an account that can use `sudo`. Otherwise you lock yourself out of your own ship.

### Passwords off, root off, key still in

Set both lines in `/etc/ssh/sshd_test.conf` (change the existing values):

<!-- astrona:playground:renew -->

```text
PasswordAuthentication no
PermitRootLogin no
```

Apply it:

```sh
sudo sshd -t -f /etc/ssh/sshd_test.conf && sudo systemctl reload sshd-test
```

Then check the result with three login attempts: `bob` with a password, `root`, and `alice` with her key:

```sh
ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=password bob@localhost true; echo "bob(pw): $?"
ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost true; echo "root: $?"
ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/alice/.ssh/id_ed25519 alice@localhost true; echo "alice(key): $?"
```

The first two fail and the third succeeds:

```text
bob@localhost: Permission denied (publickey).
bob(pw): 255
root@localhost: Permission denied (publickey).
root: 255
alice(key): 0
```

`bob` only had a password, so he is now shut out. `root` is refused outright. `alice` gets in with her key. The guard now only offers `publickey`, so guessing passwords against this port is pointless.

## Common pitfalls

> [!WARNING]
> - **`PasswordAuthentication no` before a working key.** Confirm key login for an account that can use `sudo` *first*, in a second session. Otherwise the reload locks you out.
> - **Editing the main file when a drop-in overrides it.** On Ubuntu, `sshd_config.d/*.conf` is included first and wins. Check with `sshd -T`, or put your changes in a drop-in file.
> - **`prohibit-password` when you meant `no`.** `PermitRootLogin prohibit-password` still allows root to log in with a key.
