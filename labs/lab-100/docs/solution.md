# Solution

## Step 1: Check the current state across all three hostname types

```bash
hostnamectl status
```

Check `man hostnamectl` — running it with no subcommand (or `status` explicitly) prints all three tracked values (`Static hostname`, `Transient hostname` if it differs, `Pretty hostname` if set) plus OS/kernel metadata in one view. On a freshly provisioned host, expect to see only a generic static hostname and no pretty hostname set at all.

```bash
cat /etc/hostname
hostname
```

`cat /etc/hostname` reads the on-disk static name directly, independent of any tool's interpretation; `hostname` (the older, standalone command) reports the current live/transient kernel name — on an unmodified host these two normally agree, but they answer genuinely different questions and it's worth confirming both before changing anything.

## Step 2: Set the static hostname

```bash
sudo hostnamectl set-hostname web-srv1
```

Check `man hostnamectl` and search `/set-hostname` — the page documents that with no `--static`/`--transient`/`--pretty` scoping flag, `set-hostname` updates the static name in `/etc/hostname` *and* the transient (live kernel) name together in one call, which is exactly the "correct immediately and survives reboot" requirement in the scenario — no separate step is needed to also update the running kernel value.

## Step 3: Set the pretty (cosmetic) name separately

```bash
sudo hostnamectl set-hostname "Web Server 1 (Frankfurt)" --pretty
```

Check `man hostnamectl` for the `--pretty` flag specifically — it scopes the operation to only the pretty name, stored in `/etc/machine-info`, and deliberately leaves the static/transient names (set in Step 2) untouched. Running this without `--pretty` first would have overwritten the static name with a spaces-and-punctuation string, which is exactly the kind of value that's valid for a display label but not for a real network hostname — keeping the two `set-hostname` calls separate, each scoped correctly, is the point of this step.

## Step 4: Confirm persistence directly against the file, not just the tool's live report

```bash
cat /etc/hostname
# web-srv1

cat /etc/machine-info
# PRETTY_HOSTNAME="Web Server 1 (Frankfurt)"
```

Reading the files directly (rather than trusting only `hostnamectl status`'s summary) is the actual proof of persistence — `/etc/hostname` is read at boot by systemd's early hostname-setting logic, so its content is what survives a reboot regardless of what the live kernel value happens to be at this exact moment.

## Step 5: Update `/etc/hosts`'s local-resolution line to match

```bash
grep -n '127.0.1.1' /etc/hosts
```

Check `man 5 hosts` for the file format before editing — it's a plain `IP hostname [aliases...]` per line. If a `127.0.1.1 <old-hostname>` line exists (common on Debian/Ubuntu-family systems specifically as a way to make the machine's own hostname resolve locally without DNS), update it to the new name:

```bash
sudo sed -i 's/127\.0\.1\.1.*/127.0.1.1\tweb-srv1/' /etc/hosts
```

This step is easy to skip because `hostnamectl` never touches `/etc/hosts` on its own — it only manages `/etc/hostname` and `/etc/machine-info`. A stale entry here doesn't break `hostnamectl`'s own reporting, but it can cause exactly the kind of local-resolution hiccup (a slow or warning-emitting `sudo`, or other tools that resolve their own hostname before doing anything else) described in the scenario.

## Step 6: Confirm the live state without requiring unrelated service restarts

```bash
hostnamectl status
```

Re-running `status` should now show the new static and pretty names immediately — proving the change is live right now, with nothing else on the host needing a restart; `hostnamectl`'s job is precisely to apply this without disturbing any other running service.

```bash
hostname
```

The standalone `hostname` command should also already report `web-srv1`, since it reads the live/transient kernel value that `set-hostname` updated directly — this doesn't require a new shell, only the prompt string does.

## Step 7: Start a new session to see the updated prompt

```bash
exit
ssh web-srv1
```

Or on a local session, `bash -l` / opening a new terminal tab is equivalent. The shell prompt itself (bash's `\h`/`\H` in `PS1`, or an equivalent in another shell) is typically evaluated fresh at shell/session start — an already-open interactive shell (especially one connected over SSH, where the client may have cached the string used at connection time) commonly keeps displaying the old name until a new login happens, even though `hostname`/`hostnamectl` already report the new value correctly from inside that same stale-looking shell.

## Verification

```bash
hostnamectl status
```

```text
 Static hostname: web-srv1
       Icon name: computer-vm
      Chassis: vm
   Pretty hostname: Web Server 1 (Frankfurt)
    ...
```

```bash
cat /etc/hostname
# web-srv1

hostname
# web-srv1

grep 127.0.1.1 /etc/hosts
# 127.0.1.1   web-srv1
```

## Command Summary

```bash
hostnamectl status
cat /etc/hostname
hostname

sudo hostnamectl set-hostname web-srv1
sudo hostnamectl set-hostname "Web Server 1 (Frankfurt)" --pretty

cat /etc/hostname
cat /etc/machine-info

grep -n '127.0.1.1' /etc/hosts
sudo sed -i 's/127\.0\.1\.1.*/127.0.1.1\tweb-srv1/' /etc/hosts

hostnamectl status
hostname
```
