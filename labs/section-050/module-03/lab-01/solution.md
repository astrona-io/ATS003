# Solution Walkthrough

You will make three global changes to `sshd`, add one `Match User elena`
exception, create a banner file, and reload. Everything runs on the VM's
`terminal`. The admin account logs in with a key, so disabling password
auth globally does not lock you out.

| Setting | Scope | Where |
| --- | --- | --- |
| `X11Forwarding no` | global | main body of `/etc/ssh/sshd_config` |
| `PasswordAuthentication no` | global | main body |
| `Banner /etc/ssh/sshd-banner` | global (both users) | main body |
| `PasswordAuthentication yes` | `elena` only | `Match User elena` block, at the **end** of the file |

Rule to remember: everything **above** the first `Match` line is global.
Everything from a `Match` line to the next `Match` (or end of file) applies
only when that condition matches. So all global settings go first, `Match`
blocks go last.

The authoritative check is `sshd -T` (global) and
`sshd -T -C user=NAME,host=HOST,addr=127.0.0.1` (as that user) — not
grepping the file.

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-050/module-03/lab-01
```

Five checks:

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

On the VM:

```bash
sudo sshd -T | grep -Ei 'x11forwarding|passwordauthentication|banner'
```

You will see `x11forwarding yes`, `passwordauthentication yes`,
`banner none`.

---

## Step 2: Create the banner file

```bash
echo 'Authorized access only. All activity is logged.' | sudo tee /etc/ssh/sshd-banner
```

---

## Step 3: Set the three global directives

```bash
sudo nano /etc/ssh/sshd_config
```

Find each of these lines (the setup script left `PasswordAuthentication yes`
and `X11Forwarding yes` in place) and set them to:

```text
X11Forwarding no
PasswordAuthentication no
Banner /etc/ssh/sshd-banner
```

If a directive is not present, add it — but **above** any `Match` line.
Save and exit.

Ubuntu also reads `/etc/ssh/sshd_config.d/*.conf` *before* the main file,
and the first value wins. Check nothing there overrides you:

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

## Step 5: Check syntax and reload

```bash
sudo sshd -t
sudo systemctl reload ssh || sudo systemctl reload sshd
```

Verify the effective values:

```bash
sudo sshd -T | grep -i x11forwarding
sudo sshd -T -C user=elena,host=$(hostname),addr=127.0.0.1 | grep -Ei 'passwordauthentication|banner'
sudo sshd -T -C user=victor,host=$(hostname),addr=127.0.0.1 | grep -Ei 'passwordauthentication|banner'
```

Expected: `x11forwarding no`; for `elena` `passwordauthentication yes`; for
`victor` `passwordauthentication no`; `banner /etc/ssh/sshd-banner` for
both.

**Run the check** — `x11forwarding`, `passwordauth-config`, `banner`, and
`ssh-login` now pass. All five green.

---

## Step 6: Submit

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-050/module-03/lab-01
```

---

## If a check stays red

- **`passwordauth-config` — victor still `yes`.** Something sets it before
  your global `no`. Re-run the `grep -Rns` from Step 3 over
  `/etc/ssh/sshd_config.d/` and the main file; the *first* occurrence wins,
  so comment out the stray one.
- **`passwordauth-config` — elena is `no`.** The `Match User elena` block is
  missing, misspelled, or not at the end. Everything after it (indented)
  belongs to it; make sure no later `Match` or global line follows.
- **`banner` fails.** Either `/etc/ssh/sshd-banner` does not exist, or
  `Banner` is inside a `Match` block instead of global. It must be global so
  both users get it.
- **`ssh-login` — victor still logs in.** `sshd` was not reloaded, or a
  drop-in still forces `passwordauthentication yes`. Reload and re-check
  with `sshd -T -C user=victor,...`.
- **`sshd -t` reports an error.** Usually a `Match` block with no directive
  under it, or a typo in a keyword. Fix and reload.
