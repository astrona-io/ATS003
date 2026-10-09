# Solution Walkthrough

You will replace the list of time sources in one configuration file, restart chrony, and wait for it to lock on. chrony is the ship's clockmaster: `chronyd` corrects the clock, and `chronyc` is the console you talk to it with. Everything runs in the lab virtual machine's `terminal`.

| Piece | Where | Note |
| --- | --- | --- |
| Time sources | `server` lines in `/etc/chrony/chrony.conf` | one line per server |
| Poll tuning | `minpoll` / `maxpoll` on each line | values are powers of two: `4` = 16 s, `10` = 1024 s |
| Apply changes | `sudo systemctl restart chrony` | chrony does not reload on its own |
| Check sync | `chronyc tracking`, `chronyc sources -v` | `Leap status : Normal` means synced |

## The feedback loop

Grading runs from the **host terminal**, the shell where you typed `astrona run`, not inside the virtual machine:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-040/module-01/labs/lab-01
```

Five checks:

```text
FAIL  main-servers
FAIL  fallback-servers
FAIL  maxpoll
FAIL  minpoll
FAIL  chronyd-synced
```

The first four read the configuration file and pass as soon as you save it. The last one needs chrony restarted *and* actually synchronised, which takes a little time. Run the check after each step.

---

## Step 1: Open the configuration file and clear the old sources

In the virtual machine:

```bash
sudo nano /etc/chrony/chrony.conf
```

Find every line that starts with `pool ` or `server ` and put a `#` in front of it. The task asks for exactly four sources, so the default sources (for example a `pool ntp.ubuntu.com iburst` line) must not stay active next to your new lines.

---

## Step 2: Add the four sources with poll tuning

Still in the file, add these four lines:

```text
server 0.pool.ntp.org iburst minpoll 4 maxpoll 10
server 1.pool.ntp.org iburst minpoll 4 maxpoll 10
server ntp.ubuntu.com iburst minpoll 4 maxpoll 10
server 0.debian.pool.ntp.org iburst minpoll 4 maxpoll 10
```

- `server` names one time source, one time beacon.
- `iburst` makes the first few polls fast, so sync happens in seconds, not minutes.
- `minpoll 4` and `maxpoll 10` are the poll limits as powers of two: 2⁴ = 16 seconds and 2¹⁰ = 1024 seconds.

Save and exit (`nano`: `Ctrl+O`, `Enter`, `Ctrl+X`).

**Run the check.** `main-servers`, `fallback-servers`, `minpoll`, and `maxpoll` now pass.

---

## Step 3: Restart chrony and wait for sync

chrony reads its configuration file only when it starts, so restart it:

```bash
sudo systemctl restart chrony
```

Give it 15 to 30 seconds, then look:

```bash
chronyc tracking
chronyc sources -v
```

In `chronyc tracking` you want `Leap status     : Normal`. In `chronyc sources` you want one source line with a `*` (the selected source). If it still says `Not synchronised`, wait a bit longer and check again. `iburst` usually gets there within a minute.

**Run the check.** `chronyd-synced` now passes. All five are green.

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
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-040/module-01/labs/lab-01
```

---

## If a check stays red

- **`main-servers` or `fallback-servers` fails.** A host name is misspelled, or its line is still commented out. The line must start with `server` (or `pool`) followed by the exact host name.
- **`maxpoll` or `minpoll` fails.** The option is missing or mistyped on one of the four lines. Check every line with `grep -E '^(server|pool)' /etc/chrony/chrony.conf`.
- **`chronyd-synced` fails.** Give it more time; `Leap status` has to reach `Normal`. Confirm that chrony restarted (`systemctl status chrony`) and that outgoing UDP port 123 (the NTP radio channel) is not blocked.
- **Edited the wrong file.** On this Ubuntu image the file is `/etc/chrony/chrony.conf` (not `/etc/chrony.conf`).
