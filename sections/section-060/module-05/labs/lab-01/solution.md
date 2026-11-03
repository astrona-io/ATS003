# Solution Walkthrough

You will climb the troubleshooting ladder, find three broken rungs and fix them one at a time. Everything runs on the lab virtual machine's `terminal`, except grading.

## The feedback loop

Grading runs from your **own terminal**: the shell where you typed `astrona run`:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-060/module-05/labs/lab-01
```

There are four checks: `link`, `name`, `firewall` and `portal`. They start red. Fix one rung, run the check again, and watch one more turn green.

---

## Step 1: Link and address

```bash
ip -br link show lab0
ip -br addr show lab0
```

`lab0` is `DOWN`. Switch it on and check that the address is still there:

```bash
sudo ip link set lab0 up
ip -br addr show lab0
```

The address `10.66.0.10/24` should be listed.

**Run the check**. `link` now passes.

---

## Step 2: The name

```bash
getent hosts portal.lab
```

The name resolves to `10.66.0.20`. That is the wrong call sign. Open `/etc/hosts` with an editor as root (for example `sudo nano /etc/hosts`) and change the line to:

```text
10.66.0.10 portal.lab
```

Check it again:

```bash
getent hosts portal.lab
```

**Run the check**. `name` now passes.

---

## Step 3: The firewall

The request still times out. The port rung is fine: `sudo ss -tlnp 'sport = :8443'` shows the listener. Look at the shields:

```bash
sudo nft list ruleset
```

A table `inet lab_shield` has a chain `output` with `tcp dport 8443 drop`. Delete the table:

```bash
sudo nft delete table inet lab_shield
```

**Run the check**. `firewall` now passes.

---

## Step 4: Prove it

```bash
curl http://portal.lab:8443/
```

The page `portal online` comes back.

**Run the check**. `portal` now passes, and all four checks are green. Submit from your own terminal.

---

## If a check stays red

- **`link` fails.** Check `ip -br addr show lab0`. If the address is gone, add it back with `sudo ip addr add 10.66.0.10/24 dev lab0`.
- **`name` fails.** There may be two `portal.lab` lines in `/etc/hosts`. The first one wins, so remove the wrong one.
- **`firewall` fails.** Another table may hold a second rule. Run `sudo nft list ruleset | grep 8443`.
- **`portal` fails but the other three pass.** Check the service with `systemctl status portal`.
