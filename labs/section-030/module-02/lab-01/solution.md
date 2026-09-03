# Solution Walkthrough

You will open one service and one port in the `public` zone, and make both
changes permanent. Everything runs on the VM's `terminal`.

The one idea to hold onto: firewalld keeps **two** copies of its config.

| Copy | What it is | How you change it |
| --- | --- | --- |
| Runtime | what is enforced right now | `firewall-cmd …` (no `--permanent`) |
| Permanent | what is saved to disk for next boot | `firewall-cmd … --permanent` |
| — | copy permanent → runtime | `firewall-cmd --reload` |

The clean way to change both: make the change `--permanent`, then
`--reload`.

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`, not inside the VM:

```bash
astrona test -c labs/section-030/module-02/lab-01
```

Seven checks. Three already pass from the setup script:

```text
PASS  firewalld-active
PASS  default-zone
PASS  interface-zone
FAIL  https-runtime
FAIL  https-permanent
FAIL  port-8443-runtime
FAIL  port-8443-permanent
```

Run it now to confirm, then again after each step.

---

## Step 1: See the current zone config

On the VM:

```bash
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --zone=public --list-all
```

`public` is the default zone and holds your interface. Its service list does
not include `https`; its port list is empty.

---

## Step 2: Allow the `https` service, permanently, then reload

```bash
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --reload
```

The first line writes to the permanent config. `--reload` re-reads the
permanent config into the runtime, so now both have it. Check:

```bash
sudo firewall-cmd --zone=public --list-services
sudo firewall-cmd --zone=public --list-services --permanent
```

`https` should appear in both.

**Run the check** — `https-runtime` and `https-permanent` now pass.

---

## Step 3: Allow port `8443/tcp`, permanently, then reload

```bash
sudo firewall-cmd --zone=public --add-port=8443/tcp --permanent
sudo firewall-cmd --reload
```

Check:

```bash
sudo firewall-cmd --zone=public --list-ports
sudo firewall-cmd --zone=public --list-ports --permanent
```

`8443/tcp` should appear in both.

**Run the check** — `port-8443-runtime` and `port-8443-permanent` now pass.
All seven green.

---

## Step 4: Submit

When `astrona test` shows all seven `PASS`, submit from the host terminal:

```bash
astrona submit -c labs/section-030/module-02/lab-01
```

---

## If a check stays red

- **`…-runtime` passes but `…-permanent` fails.** You added it without
  `--permanent`. Re-run the command with `--permanent`, then
  `sudo firewall-cmd --reload`.
- **`…-permanent` passes but `…-runtime` fails.** You added it with
  `--permanent` but never reloaded. Run `sudo firewall-cmd --reload`.
- **Shortcut if you already changed runtime only.** `sudo firewall-cmd
  --runtime-to-permanent` copies the current runtime into the permanent
  config in one go.
- **Nothing changed.** Make sure you passed `--zone=public` — edits without
  a zone go to the default zone, which here is `public`, but being explicit
  avoids surprises.
