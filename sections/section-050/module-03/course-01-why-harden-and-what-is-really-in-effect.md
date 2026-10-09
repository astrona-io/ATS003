# Why Harden And What Is Really In Effect

Astronaut, before you change the airlock guard's standing orders, you need two things: a clear idea of what you are defending against, and a way to read the orders the guard really follows. This part gives you both.

## What hardening defends against

Scanners try common user names and password lists against every SSH (Secure Shell) server they find. Hardening removes what those attempts need and limits the damage if one succeeds.

### The four moves

- **Take away passwords.** Key login (opening the airlock with a keycard) cannot be brute-forced the way a password can. `PasswordAuthentication no` is the single biggest change.
- **Limit who can log in.** With an allow list of accounts, an attacker who guesses the password of some *other* account still gets nothing.
- **Cut the surface.** No root login, a short time to log in, few attempts per connection, and no port forwarding unless someone needs it.
- **Keep a record.** Keep the logs, and add a rate limiter (fail2ban or sshguard) at the firewall.

### The layers around the airlock

Hardening `sshd` is one layer of protecting administrator access. In front of it sits the **firewall** (the ship's shields): allow port 22 only from known addresses or a VPN (virtual private network), and add a log-driven rate limiter so repeat offenders are blocked before they reach `sshd`.

Behind it sit **key hygiene** (keys with a passphrase, `ssh-agent`, one key per person instead of one shared key), a **bastion or jump host** so backend machines are never exposed directly, and, for higher assurance, two-factor login (`AuthenticationMethods publickey,keyboard-interactive`) or **SSH certificates** instead of an ever-growing `authorized_keys` file. Moving the listening `Port` away from 22 makes the logs quieter, but it is not a security control on its own.

## The `sshd` command

`sshd` normally runs as a background service. Three read-only ways to call it are how you work on its configuration safely, and you will use them in every step of this module.

### Test, dump, and dump for one connection

- `sshd -t` is the **t**est. It reads the configuration, reports errors and exits with a non-zero code on failure. It does not touch the running service. Run it before every reload.
- `sshd -T` prints the **entire effective configuration**: every keyword with the value it resolved to. This is what the service would really use. The file alone does not show it, because of defaults and the "first value wins" rule.
- `sshd -T -C user=…,host=…,addr=…` prints the same dump, but worked out **as if for that one connection**, so `Match` blocks are applied. This is how you test a `Match` block without connecting.

Add `-f /etc/ssh/sshd_test.conf` to any of them to point it at the playground's throwaway file instead of the real one.

## Reading the effective configuration

`sshd_config` has a default for every keyword you do not set. Together with "first value wins", that makes the file a poor guide to what is really in effect. `sshd -T` is the true picture.

### See the configuration as the service sees it

Ask the test server on port 2222 for the six settings this module hardens:

<!-- astrona:playground:renew -->

```sh
sudo sshd -T -f /etc/ssh/sshd_test.conf | grep -E '^(passwordauthentication|permitrootlogin|pubkeyauthentication|maxauthtries|logingracetime|x11forwarding) '
```

You get the wide-open starting values:

```text
passwordauthentication yes
permitrootlogin yes
pubkeyauthentication yes
maxauthtries 6
logingracetime 120
x11forwarding yes
```

Every line here is something to tighten. `sshd -T` is also how you check that a change you made really took effect: the file can say one thing while the service uses another.

> [!TIP]
> Make `sshd -T` your proof, every time. After any change to `sshd_config`, grep the setting out of `sshd -T` before you believe it. Exam graders check the same effective values.

## Common pitfalls

> [!WARNING]
> - **Trusting the file instead of `sshd -T`.** A line in the file can be overridden by an earlier value or a default. Only `sshd -T` shows what the service uses.
> - **Treating a new `Port` as security.** Moving SSH off port 22 cuts log noise, not risk.
> - **Editing the real `sshd_config` in the playground.** Port 22 carries your session. Work only on `/etc/ssh/sshd_test.conf` and port 2222.
