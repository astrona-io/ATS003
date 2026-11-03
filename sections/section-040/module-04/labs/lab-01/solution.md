# Solution Walkthrough

You will tell the resolver about the lab server, test a short name and pin one name in the pocket address book. Everything runs on the lab virtual machine's `terminal`, except grading.

## The feedback loop

Grading runs from your **own terminal**: the shell where you typed `astrona run`:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-040/module-04/labs/lab-01
```

There are four checks: `dropin`, `resolver-live`, `short-name` and `hosts-override`. Run it after each step.

---

## Step 1: Write the drop-in and restart the resolver

Create the folder and the file:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo nano /etc/systemd/resolved.conf.d/10-lab.conf
```

Put this in the file:

```ini
[Resolve]
DNS=10.55.0.53
Domains=lab.example
```

Apply it and look at the status:

```bash
sudo systemctl restart systemd-resolved
resolvectl status | grep -E 'DNS Servers|DNS Domain'
```

**Run the check**. `dropin` and `resolver-live` now pass.

---

## Step 2: Test the short name

```bash
sudo resolvectl flush-caches
getent hosts db
```

You should see `203.0.113.20`, followed by the name. The search domain turned `db` into `db.lab.example`.

**Run the check**. `short-name` now passes.

---

## Step 3: Override `www.lab.example`

The pocket address book is read first, so a line there wins over DNS:

```bash
echo '198.51.100.80 www.lab.example' | sudo tee -a /etc/hosts
getent hosts www.lab.example
dig +short @10.55.0.53 www.lab.example
```

`getent` shows `198.51.100.80`. `dig` still shows `203.0.113.10`, because `dig` asks the server and never reads `/etc/hosts`.

**Run the check**. `hosts-override` now passes, and all four checks are green. Submit from your own terminal.

---

## If a check stays red

- **`dropin` fails.** The folder name or the keys are wrong. The file must end in `.conf`, have a `[Resolve]` line, and use `DNS=` and `Domains=` exactly.
- **`resolver-live` fails.** You did not restart the resolver. Run `sudo systemctl restart systemd-resolved`.
- **`short-name` fails.** Flush the cache with `sudo resolvectl flush-caches`, and check that `dig +short @10.55.0.53 db.lab.example` answers.
- **`hosts-override` fails.** Check for a typo in `/etc/hosts`, and that `grep '^hosts:' /etc/nsswitch.conf` still has `files` first.
