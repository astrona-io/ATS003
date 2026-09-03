# Solution Walkthrough

You will replace the time-source list in one config file, restart the
daemon, and wait for it to lock on. Everything runs on the VM's `terminal`.

| Piece | Where | Note |
| --- | --- | --- |
| Time sources | `server` lines in `/etc/chrony/chrony.conf` | one line per server |
| Poll tuning | `minpoll` / `maxpoll` on each line | values are powers of two: `4` = 16 s, `10` = 1024 s |
| Apply changes | `sudo systemctl restart chrony` | chrony does not reload on its own |
| Check sync | `chronyc tracking`, `chronyc sources -v` | `Leap status : Normal` means synced |

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`, not inside the VM:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-040/module-01/lab-01
```

Five checks:

```text
FAIL  main-servers
FAIL  fallback-servers
FAIL  maxpoll
FAIL  minpoll
FAIL  chronyd-synced
```

The first four read the config file and pass as soon as you save it. The
last needs the daemon restarted *and* actually synced, which takes a little
time. Run the check after each step.

---

## Step 1: Open the config and clear the old sources

On the VM:

```bash
sudo nano /etc/chrony/chrony.conf
```

Find every line that starts with `pool ` or `server ` and put a `#` in
front of it. This matters: the checks look at the **first** line for each
host, so a leftover default `pool ntp.ubuntu.com iburst` (with no
`maxpoll`) would be read instead of your new line and fail the poll checks.

---

## Step 2: Add the four sources with poll tuning

Still in the file, add these four lines:

```text
server 0.pool.ntp.org iburst minpoll 4 maxpoll 10
server 1.pool.ntp.org iburst minpoll 4 maxpoll 10
server ntp.ubuntu.com iburst minpoll 4 maxpoll 10
server 0.debian.pool.ntp.org iburst minpoll 4 maxpoll 10
```

- `server` names one time source.
- `iburst` makes the first few polls fast, so sync happens in seconds not
  minutes.
- `minpoll 4` / `maxpoll 10` are the poll bounds as powers of two: 2⁴ = 16 s
  and 2¹⁰ = 1024 s.

Save and exit (`nano`: `Ctrl+O`, `Enter`, `Ctrl+X`).

**Run the check** — `main-servers`, `fallback-servers`, `minpoll`, and
`maxpoll` now pass.

---

## Step 3: Restart chrony and wait for sync

```bash
sudo systemctl restart chrony
```

Give it 15–30 seconds, then look:

```bash
chronyc tracking
chronyc sources -v
```

In `chronyc tracking` you want `Leap status     : Normal`. In
`chronyc sources` you want one source line with a `*` (the selected source).
If it still says `Not synchronised`, wait a bit longer and re-check —
`iburst` usually gets there within a minute.

**Run the check** — `chronyd-synced` now passes. All five green.

---

## Step 4: Submit

When `astrona submit` shows all five `PASS`:

```text
PASS  main-servers
PASS  fallback-servers
PASS  maxpoll
PASS  minpoll
PASS  chronyd-synced
```

Submit from the host terminal:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-040/module-01/lab-01
```

---

## If a check stays red

- **`maxpoll` or `minpoll` fails even though your line looks right.** There
  is another line for that host higher up in the file (a default `pool` or
  `server` line). Comment it out — the check reads the first match.
- **`chronyd-synced` fails.** Give it more time; `Leap status` has to reach
  `Normal`. Confirm the daemon restarted (`systemctl status chrony`) and
  that outbound UDP port 123 is not blocked.
- **Edited the wrong file.** On this Ubuntu image the file is
  `/etc/chrony/chrony.conf` (not `/etc/chrony.conf`).
