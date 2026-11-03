# Solution Walkthrough

You make three global changes to `sshd`, add one `Match User elena` exception, create a banner file, and reload. Everything runs in the training ship's `terminal`. Your administrator account logs in with a key, so turning off password login for everyone does not lock you out.

`sshd` is the ship's airlock guard, and `/etc/ssh/sshd_config` holds its standing orders. A `Match` block is an exception for one crew member.

| Setting | Scope | Where |
| --- | --- | --- |
| `X11Forwarding no` | global | main body of `/etc/ssh/sshd_config` |
| `PasswordAuthentication no` | global | main body |
| `Banner /etc/ssh/sshd-banner` | global (both users) | main body |
| `PasswordAuthentication yes` | `elena` only | `Match User elena` block, at the **end** of the file |

The rule to remember: everything **above** the first `Match` line is global. Everything from a `Match` line to the next `Match` (or the end of the file) applies only when that condition matches. So all global settings go first, and `Match` blocks go last.

The real check is `sshd -T` (global) and `sshd -T -C user=NAME,host=HOST,addr=127.0.0.1` (as that user), not a `grep` of the file.

## The feedback loop

Grading runs from the **host terminal**: the shell where you typed `astrona run`, not inside the training ship.

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-050/module-03/labs/lab-01
```

Before you start, the grader reports five checks:

```text
PASS  sshd-service
FAIL  x11forwarding
FAIL  passwordauth-config
FAIL  banner
FAIL  ssh-login
```

Run it after each step.

---

## Step 1: See the current effective values

On the training ship:

```bash
sudo sshd -T | grep -Ei 'x11forwarding|passwordauthentication|banner'
```

You see `x11forwarding yes`, `passwordauthentication yes` and `banner none`.

---

## Step 2: Create the banner file

Save this as `/etc/ssh/sshd-banner` (open it with `sudo` in your editor, for example `sudo nano /etc/ssh/sshd-banner`):

```text
Authorized access only. All activity is logged.
```

The same result in one command is `echo 'Authorized access only. All activity is logged.' | sudo tee /etc/ssh/sshd-banner`.

---

## Step 3: Set the three global settings

Open the main file:

```bash
sudo nano /etc/ssh/sshd_config
```

Find each of these lines (the setup script left `PasswordAuthentication yes` and `X11Forwarding yes` in place) and set them to:

```text
X11Forwarding no
PasswordAuthentication no
Banner /etc/ssh/sshd-banner
```

If a setting is not there, add it, but **above** any `Match` line. Save and exit.

Ubuntu also reads `/etc/ssh/sshd_config.d/*.conf` *before* the rest of the main file, and the first value found wins. Check that nothing there overrides you:

```bash
sudo grep -Rns -Ei 'passwordauthentication|x11forwarding|banner' /etc/ssh/sshd_config.d/
```

If a file there sets any of these, comment those lines out.

---

## Step 4: Add the `elena` exception

At the very **bottom** of `/etc/ssh/sshd_config`, add:

```text
Match User elena
    PasswordAuthentication yes
```

Save and exit.

---

## Step 5: Check the syntax and reload

Apply it. Test first, then reload:

```bash
sudo sshd -t
sudo systemctl reload ssh || sudo systemctl reload sshd
```

Then check the effective values:

```bash
sudo sshd -T | grep -i x11forwarding
sudo sshd -T -C user=elena,host=$(hostname),addr=127.0.0.1 | grep -Ei 'passwordauthentication|banner'
sudo sshd -T -C user=victor,host=$(hostname),addr=127.0.0.1 | grep -Ei 'passwordauthentication|banner'
```

Look for `x11forwarding no`; `passwordauthentication yes` for `elena`; `passwordauthentication no` for `victor`; and `banner /etc/ssh/sshd-banner` for both.

**Run the check.** `x11forwarding`, `passwordauth-config`, `banner` and `ssh-login` now pass. All five checks are green.

---

## Step 6: Submit

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-050/module-03/labs/lab-01
```

---

## If a check stays red

- **`passwordauth-config`: `victor` is still `yes`.** Something sets it before your global `no`. Run the `grep -Rns` from Step 3 again over `/etc/ssh/sshd_config.d/` and the main file. The *first* value found wins, so comment out the stray one.
- **`passwordauth-config`: `elena` is `no`.** The `Match User elena` block is missing, misspelled, or not at the end. Everything indented after it belongs to it. Make sure no later `Match` or global line follows.
- **`banner` fails.** Either `/etc/ssh/sshd-banner` does not exist, or `Banner` sits inside a `Match` block instead of in the global part. It must be global, so both users get it.
- **`ssh-login`: `victor` can still log in.** `sshd` was not reloaded, or a drop-in file still forces `passwordauthentication yes`. Reload and check again with `sshd -T -C user=victor,...`.
- **`sshd -t` reports an error.** Usually a `Match` block with no setting under it, or a typo in a keyword. Fix it and reload.
