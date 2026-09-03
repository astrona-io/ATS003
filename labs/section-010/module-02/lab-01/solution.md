# Solution Walkthrough

You will give this machine three kinds of name: the persistent system name,
the pretty display name, and the `/etc/hosts` entry the machine uses to
resolve itself.

Everything runs on the VM's `terminal`.

Three names, three places:

| Name | Where it lives | How to set it |
| --- | --- | --- |
| Static / live hostname | `/etc/hostname` + running kernel | `sudo hostnamectl set-hostname web-srv1` |
| Pretty (display) name | `/etc/machine-info` | `sudo hostnamectl set-hostname "…" --pretty` |
| Local resolution entry | `/etc/hosts`, the `127.0.1.1` line | edit the file |

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`, not the shell inside the VM:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-010/module-02/lab-01
```

It runs four checks and prints one line each:

```text
FAIL  static-hostname
FAIL  transient-hostname
FAIL  pretty-hostname
FAIL  hosts-entry
```

Run it now to see them all fail, then run it again after every step below.

---

## Step 1: Look at the current names

On the VM:

```bash
hostnamectl
cat /etc/hostname
grep 127.0.1.1 /etc/hosts
```

You will see the hostname is `ubuntu-2404-base` everywhere, and the
`/etc/hosts` line reads:

```text
127.0.1.1	ubuntu-2404-base
```

---

## Step 2: Set the static and live hostname

One command sets both the persisted name (`/etc/hostname`) and the name the
`hostname` command reports right now:

```bash
sudo hostnamectl set-hostname web-srv1
```

Confirm:

```bash
hostname
cat /etc/hostname
```

Both should print `web-srv1`.

**Run the check** on the host terminal — `static-hostname` and
`transient-hostname` now pass.

---

## Step 3: Set the pretty hostname

The pretty name is free-form text (spaces and punctuation allowed). It needs
the `--pretty` flag and quotes around the value:

```bash
sudo hostnamectl set-hostname "Web Server 1 (Frankfurt)" --pretty
```

Confirm it is exactly right:

```bash
hostnamectl status --pretty
```

Output must be exactly `Web Server 1 (Frankfurt)` — same capitalisation,
same spacing, same parentheses.

**Run the check** — `pretty-hostname` now passes.

---

## Step 4: Fix the /etc/hosts entry

Open the file:

```bash
sudo nano /etc/hosts
```

Find the line that starts with `127.0.1.1`. Change the name on it from
`ubuntu-2404-base` to `web-srv1`, so it reads:

```text
127.0.1.1	web-srv1
```

Leave the `127.0.0.1 localhost` line and everything else alone. Save and
exit (`nano`: `Ctrl+O`, `Enter`, `Ctrl+X`).

Confirm:

```bash
grep 127.0.1.1 /etc/hosts
```

**Run the check** — `hosts-entry` now passes. All four green.

---

## Step 5: Submit

When `astrona submit` shows all four `PASS`:

```text
PASS  static-hostname
PASS  transient-hostname
PASS  pretty-hostname
PASS  hosts-entry
```

Submit from the host terminal:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-010/module-02/lab-01
```

---

## If a check stays red

- **`pretty-hostname` fails.** The text does not match exactly. Re-run the
  Step 3 command with the value copied character-for-character, including the
  capital letters and the `(Frankfurt)` in parentheses.
- **`static-hostname` passes but `transient-hostname` fails (or vice versa).**
  You set the name with the bare `hostname web-srv1` command (transient only)
  or by editing `/etc/hostname` by hand (static only). Run
  `sudo hostnamectl set-hostname web-srv1` — it does both at once.
- **`hosts-entry` fails.** You changed the wrong line, or added a new line
  instead of editing the existing `127.0.1.1` one. There must be a single
  `127.0.1.1` line and it must contain `web-srv1`.
