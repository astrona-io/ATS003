# OpenSSH Server Hardening

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-050/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-03/playground
> astrona destroy ssh-hardening-playground
> ```

Any `sshd` reachable from the internet gets a steady stream of automated login attempts — scanners working through common usernames and password lists, around the clock. **Hardening** the SSH server is about removing the things those attempts rely on and shrinking what a successful one could do:

- **Take away passwords.** Key-based authentication cannot be brute-forced the way a password can. `PasswordAuthentication no` is the single biggest change.
- **Limit who can log in.** An allowlist of accounts means an attacker who guesses a valid credential for some *other* account still gets nothing.
- **Cut the surface.** No root login, a short window to authenticate, few attempts per connection, no port forwarding unless it is needed.
- **Keep a record.** Logs plus a rate-limiter (fail2ban, sshguard) at the firewall.

The server's behaviour is set in **`/etc/ssh/sshd_config`**, and — the part that trips people up — overridden per-user, per-group, or per-address by **`Match` blocks** at the bottom of that file. This module works through both.

## Learning objectives

After this module you can:

- Explain the threat SSH hardening addresses and name the highest-impact settings.
- Read the effective configuration with `sshd -T`, and explain first-match-wins and the `sshd_config.d/` drop-in order.
- Disable password authentication and root login, and confirm key authentication still works.
- Restrict who may log in with `AllowUsers` / `AllowGroups`, and explain why an allowlist beats a denylist.
- Write a `Match` block for a per-user or per-address exception and verify it with `sshd -T -C`.
- Validate a config with `sshd -t` and reload without locking yourself out.

## Before you start

This module assumes you can open a shell, use `sudo`, edit a text file, and have connected over SSH with a key before. `sshd_config` keyword syntax, `Match`, and key-versus-password authentication are explained as they come up. The firewall modules — restricting *who can reach* port 22 — are the complementary layer to what is here.

The playground is a single VM with a deliberate safety net: a **second, throwaway `sshd` on port 2222**, its own config file `/etc/ssh/sshd_test.conf`, started **wide open**. Two local users exist — `alice` (has a key at `~/.ssh/id_ed25519`, in group `sshusers`) and `bob` (password `bobpass`, no key).

> [!WARNING]
> Do **not** edit `/etc/ssh/sshd_config` or restart `ssh.service`. Port 22 carries your `astrona ssh` session; a bad change there locks you out until `astrona destroy` and a fresh `astrona run`. Every command below targets port **2222** and `sshd_test.conf`, which you can break freely.

The loop is: edit `/etc/ssh/sshd_test.conf` → `sudo sshd -t -f /etc/ssh/sshd_test.conf` → `sudo systemctl reload sshd-test` → test with `ssh -p 2222 …`. The test `ssh` commands include `-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null` so a changed host key never blocks you. On a real server the config file is the default and those `-f` flags are not needed.

## Where this fits

Hardening `sshd` is one layer of protecting admin access. In front of it sits the **firewall** — restrict port 22 to known source addresses or a VPN, and add a log-driven rate-limiter (fail2ban, sshguard) so repeat offenders are blocked at the packet level. Behind it sit **key hygiene** (passphrase-protected keys, `ssh-agent`, one key per person not one shared key), a **bastion / jump host** so backends are never exposed directly, and, for higher assurance, **2FA** (`AuthenticationMethods publickey,keyboard-interactive`) or **SSH certificates** instead of piling entries into `authorized_keys`. Changing the listen `Port` away from 22 quiets the logs but is not a security control on its own.

## The `sshd` command

`sshd` is normally a daemon, but three read-only invocations are how you work on its config safely:

- `sshd -t` — **t**est: parse the config, report errors, exit non-zero on failure. Touches nothing running. Run it before every reload.
- `sshd -T` — dump the **entire effective configuration**, every keyword with its resolved value. This is "what the daemon would actually use", which the file alone does not show because of defaults and first-match-wins.
- `sshd -T -C user=…,host=…,addr=…` — the same dump, but evaluated **as if for that specific connection**, so `Match` blocks are applied. The way to test a `Match` without connecting.

Add `-f /etc/ssh/sshd_test.conf` to point any of them at the playground's throwaway file instead of the real one.

## Reading the effective configuration

`sshd_config` has defaults for everything you do not set, plus a first-match rule that makes "what is actually in effect" hard to read from the file alone.

> [!TIP]
> **Try it — the config as the daemon sees it**
>
> ```sh
> sudo sshd -T -f /etc/ssh/sshd_test.conf | grep -E '^(passwordauthentication|permitrootlogin|pubkeyauthentication|maxauthtries|logingracetime|x11forwarding) '
> ```
>
> Expect the wide-open starting values:
>
> ```text
> passwordauthentication yes
> permitrootlogin yes
> pubkeyauthentication yes
> maxauthtries 6
> logingracetime 120
> x11forwarding yes
> ```
>
> Every line here is something to tighten. `sshd -T` is also how you check whether a change you made in the file actually took effect — the file can say one thing and the daemon use another.

## First match wins, and the drop-in directory

Two rules govern which value `sshd` uses:

1. **The first value obtained for a keyword wins.** A second `PasswordAuthentication` line later in the file is ignored.
2. **`Include` is processed where it appears.** On Debian and Ubuntu, `/etc/ssh/sshd_config` begins with `Include /etc/ssh/sshd_config.d/*.conf`, so any setting in a drop-in file is obtained *first* and beats the same setting written later in the main file.

The practical consequence: on a stock Ubuntu box, editing `PasswordAuthentication` in `/etc/ssh/sshd_config` can do **nothing**, because a file in `sshd_config.d/` already set it. Put your changes in a drop-in (`/etc/ssh/sshd_config.d/10-hardening.conf`) or check with `sshd -T` that they land. (The playground's `sshd_test.conf` deliberately does *not* `Include` anything, so it stays predictable.)

## Forcing keys and locking down root

The two highest-impact lines:

```text
PasswordAuthentication no
PermitRootLogin no
```

`PermitRootLogin` also takes `prohibit-password` (root may still use a key) — use `no` if root should never log in over SSH at all. Before turning passwords off on a real server, **confirm key authentication already works** for an account that can `sudo`.

> [!TIP]
> **Try it — passwords off, root off, key still in**
>
> Set both lines in `/etc/ssh/sshd_test.conf`, then:
>
> ```sh
> sudo sshd -t -f /etc/ssh/sshd_test.conf && sudo systemctl reload sshd-test
> ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=password bob@localhost true; echo "bob(pw): $?"
> ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost true; echo "root: $?"
> ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/alice/.ssh/id_ed25519 alice@localhost true; echo "alice(key): $?"
> ```
>
> Expect the first two to fail and the third to succeed:
>
> ```text
> bob@localhost: Permission denied (publickey).
> bob(pw): 255
> root@localhost: Permission denied (publickey).
> root: 255
> alice(key): 0
> ```
>
> `bob` had only a password, so he is now shut out; `root` is refused outright; `alice` authenticates with her key. Password guessing against this port is now pointless.

## Restricting who may log in

By default every account on the machine can attempt SSH login. `AllowUsers` or `AllowGroups` turns that into an allowlist — if either is present, **only** listed users/groups may authenticate, everyone else is refused before the password or key is even checked.

Prefer an allowlist to `DenyUsers`/`DenyGroups`: a denylist only stops the accounts you thought to name, and misses `postgres`, `jenkins`, or tomorrow's new service account.

> [!TIP]
> **Try it — only `sshusers` may log in**
>
> Add `AllowGroups sshusers` to `sshd_test.conf` (or `AllowUsers alice`), reload, and test both users — `alice` is in that group, `bob` is not:
>
> ```sh
> sudo sshd -t -f /etc/ssh/sshd_test.conf && sudo systemctl reload sshd-test
> ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/alice/.ssh/id_ed25519 alice@localhost true; echo "alice: $?"
> ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=password bob@localhost true; echo "bob: $?"
> ```
>
> Expect `alice` in, `bob` refused regardless of credentials:
>
> ```text
> alice: 0
> bob@localhost: Permission denied (publickey,password).
> bob: 255
> ```
>
> `sudo journalctl -u sshd-test` shows the reason — `User bob from 127.0.0.1 not allowed because none of user's groups are listed in AllowGroups`.

## Shrinking the attack surface

Beyond authentication, a few limits reduce what an attacker (or a bug) can do per connection:

- `MaxAuthTries 3` — failed attempts before the connection is dropped (default 6).
- `LoginGraceTime 20` — seconds to authenticate before disconnect (default 120).
- `MaxStartups 10:30:100` — start refusing new unauthenticated connections once 10 are pending.
- `X11Forwarding no`, `AllowTcpForwarding no`, `AllowAgentForwarding no` — turn off forwarding features unless a specific workflow needs them; they are pivot routes from a compromised session.
- `ClientAliveInterval 300` / `ClientAliveCountMax 2` — drop idle sessions.

> [!TIP]
> **Try it — the per-connection attempt limit**
>
> Set `MaxAuthTries 2`, reload, and make repeated wrong-password attempts in one connection:
>
> ```sh
> sudo sshd -t -f /etc/ssh/sshd_test.conf && sudo systemctl reload sshd-test
> ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
>     -o PreferredAuthentications=password -o NumberOfPasswordPrompts=6 bob@localhost
> ```
>
> Type wrong passwords. The server cuts the connection after the second:
>
> ```text
> Permission denied, please try again.
> Permission denied, please try again.
> Received disconnect from 127.0.0.1 port 2222:2: Too many authentication failures
> ```
>
> A scanner that would have tried dozens of passwords per connection gets two. (Combine with a firewall rate-limiter to also cap *connections* per minute.)

## `Match` blocks: exceptions to the rules

A `Match` block applies its settings **only** when its criteria match the connection — a user, a group, an address, a local port. Everything from a `Match` line to the next `Match` (or end of file) is inside that block, which is why `Match` blocks go at the **bottom**: a `Match` left open above normal settings would capture them all.

```text
Match User bob
    PasswordAuthentication yes
    X11Forwarding no
```

Only a subset of keywords are valid inside `Match` (authentication and session options, mostly). A `Match` block *does* override a global setting, regardless of order — so the pattern "deny globally, allow for one case" works.

> [!TIP]
> **Try it — password auth for `bob` only**
>
> With `PasswordAuthentication no` globally (from earlier), append the `Match User bob` block above, reload, and check the resolved value for each user with `sshd -T -C`:
>
> ```sh
> sudo sshd -t -f /etc/ssh/sshd_test.conf && sudo systemctl reload sshd-test
> sudo sshd -T -f /etc/ssh/sshd_test.conf -C user=bob,host=localhost,addr=127.0.0.1   | grep '^passwordauthentication '
> sudo sshd -T -f /etc/ssh/sshd_test.conf -C user=alice,host=localhost,addr=127.0.0.1 | grep '^passwordauthentication '
> ```
>
> Expect the setting to differ by user:
>
> ```text
> passwordauthentication yes
> passwordauthentication no
> ```
>
> `sshd -T -C` evaluates the config *as if* for that connection, `Match` blocks and all — the way to test a `Match` without actually connecting. `bob` keeps password auth; everyone else does not.

## Validating before you reload

`sshd -t` parses the config and reports errors without touching the running daemon. Run it **every time**, before every reload — a syntax error that reaches `systemctl restart` can leave you with a daemon that will not start.

> [!TIP]
> **Try it — a broken config caught before it ships**
>
> Add a bad line to `sshd_test.conf`, e.g. `PermitRootLogin maybe`, then:
>
> ```sh
> sudo sshd -t -f /etc/ssh/sshd_test.conf ; echo "exit: $?"
> ```
>
> Expect a specific complaint and a non-zero exit:
>
> ```text
> /etc/ssh/sshd_test.conf: line 21: Bad yes/no/prohibit-password/... argument: maybe
> exit: 255
> ```
>
> Because `sshd-test.service` also runs `sshd -t` as `ExecStartPre`, a broken file makes the reload fail loudly instead of bringing the daemon down. On a real server, `sshd -t` passing plus a second SSH session already open is what makes a reload safe. Remove the bad line afterwards.

> [!WARNING]
> **Common pitfalls**
>
> - **`PasswordAuthentication no` before a working key.** Confirm key login for a `sudo`-capable account *first*, in a second session. Otherwise the reload locks you out.
> - **Editing the main file when a drop-in overrides it.** On Ubuntu, `sshd_config.d/*.conf` is Included first and wins. Check with `sshd -T`, or put changes in a drop-in.
> - **A `Match` block not at the bottom.** It captures every line until the next `Match` or EOF — global settings placed after it silently become conditional.
> - **`AllowUsers` without your own account.** If the allowlist omits the admin user, nobody can log in. Include yourself, and keep a session open when you reload.
> - **Reloading without `sshd -t`.** A syntax error that reaches `restart` can stop the daemon entirely. Test first, every time.
> - **`DenyUsers` as the primary control.** A denylist misses accounts you did not name. Use `AllowUsers` / `AllowGroups`.
> - **`prohibit-password` when you meant `no`.** `PermitRootLogin prohibit-password` still allows key-based root login.
> - **New `Port` but old firewall.** Changing `Port` needs a matching firewall rule (and on SELinux systems, `semanage port -a`).
