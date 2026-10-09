# Solution Walkthrough

You will build two nftables tables: `inet filter` for the incoming and
outgoing rules, and `ip nat` for the port redirect. Every command runs in
the `terminal` of the lab virtual machine (your training ship).

Every nftables policy has the same three layers. Think of them as a shield
program, its checkpoints, and the lines each checkpoint reads:

| Layer | What it is | Command |
| --- | --- | --- |
| Table | a container, tied to one address family | `sudo nft add table inet filter` |
| Chain | a hook point plus a default policy | `sudo nft add chain inet filter input { type filter hook input priority 0 \; policy accept \; }` |
| Rule | one match plus an action, read top to bottom | `sudo nft add rule inet filter input tcp dport 5000 drop` |

## The feedback loop

Grading runs from your **own terminal**, the shell where you typed
`astrona run`, not inside the virtual machine:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-030/module-01/labs/lab-01
```

There are four checks. At the start, all four fail:

```text
FAIL  port-5000-drop
FAIL  port-6000-redirect
FAIL  port-6002-source-restriction
FAIL  egress-block
```

Run it now, then again after each step.

---

## Step 1: Look at the starting point

On the virtual machine, list the ruleset:

```bash
sudo nft list ruleset
```

It prints nothing: the ruleset is empty. Now check that the redirect target
is up:

```bash
sudo ss -tulpn | grep 6001
```

A small Python web server is listening on `6001`.

---

## Step 2: Create the filter table and its two chains

```bash
sudo nft add table inet filter
sudo nft add chain inet filter input '{ type filter hook input priority 0 ; policy accept ; }'
sudo nft add chain inet filter output '{ type filter hook output priority 0 ; policy accept ; }'
```

`type filter hook input` is what attaches the chain to incoming traffic. A
chain without a hook line is never used. `policy accept` means "allow
anything that no rule drops".

No check changes yet, because the chains have no rules.

---

## Step 3: Drop incoming port 5000

```bash
sudo nft add rule inet filter input tcp dport 5000 drop
```

Check it:

```bash
sudo nft list chain inet filter input
```

**Run the check.** `port-5000-drop` now passes.

---

## Step 4: Limit port 6002 to one source: accept first, then drop

Order matters. Add the **accept** rule first, so it sits above the drop:

```bash
sudo nft add rule inet filter input tcp dport 6002 ip saddr 192.168.10.80 accept
sudo nft add rule inet filter input tcp dport 6002 drop
```

Check the order. The accept line must appear before the drop line:

```bash
sudo nft -a list chain inet filter input
```

**Run the check.** `port-6002-source-restriction` now passes.

---

## Step 5: Block outgoing traffic to 192.168.10.70

```bash
sudo nft add rule inet filter output ip daddr 192.168.10.70 drop
```

**Run the check.** `egress-block` now passes.

---

## Step 6: Create the NAT table and the redirect

The redirect lives in a separate `ip nat` table, with a chain of
`type nat` on the `prerouting` hook:

```bash
sudo nft add table ip nat
sudo nft add chain ip nat prerouting '{ type nat hook prerouting priority -100 ; policy accept ; }'
sudo nft add rule ip nat prerouting tcp dport 6000 redirect to :6001
```

`priority -100` (also called `dstnat`) is the standard priority for a NAT
chain on `prerouting`. `redirect to :6001` changes the destination port to
`6001` on this same host.

Check it:

```bash
sudo nft list chain ip nat prerouting
```

**Run the check.** `port-6000-redirect` now passes, and all four checks are
green.

---

## Step 7: Submit

When `astrona submit` shows all four `PASS`:

```text
PASS  port-5000-drop
PASS  port-6000-redirect
PASS  port-6002-source-restriction
PASS  egress-block
```

submit from your own terminal:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-030/module-01/labs/lab-01
```

These rules live only in the running kernel. To keep them after a reboot,
you would run `sudo nft list ruleset | sudo tee /etc/nftables.conf` and
then `sudo systemctl enable nftables`. That is not needed to pass this lab.

---

## If a check stays red

- **A rule was added, but the check still fails.** The chain probably has
  no hook. Create it again with the full
  `{ type filter hook input priority 0 ; policy accept ; }` form.
- **`port-6002-source-restriction` fails.** Either the drop is above the
  accept, or the accept rule names the source before the port (the checker
  wants `tcp dport 6002` first on that line). Fix it without wiping
  everything: run `sudo nft flush chain inet filter input`, then add the
  `input` rules from Steps 3 and 4 again, in order (5000 drop, 6002 accept,
  6002 drop).
- **`port-5000-drop` or `egress-block` fails, but the rule is there.** The
  checker wants the verdict right after the match. A rule such as
  `tcp dport 5000 counter drop` does not count.
- **`port-6000-redirect` fails.** Check that the rule reads exactly
  `tcp dport 6000 redirect to :6001` (with the colon), and that
  `sudo ss -tulpn | grep 6001` still shows a listener.
- **Everything is wrong and you want a clean start.** `sudo nft flush
  ruleset` empties the ruleset; then start again from Step 2.
