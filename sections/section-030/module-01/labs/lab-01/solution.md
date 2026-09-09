# Solution Walkthrough

You will build two nftables tables: `inet filter` for the inbound/outbound
rules, and `ip nat` for the port redirect. Everything runs on the VM's
`terminal`.

The shape of every nftables policy is the same three layers:

| Layer | What it is | Command |
| --- | --- | --- |
| Table | a container, by address family | `sudo nft add table inet filter` |
| Chain | a hook point + default policy | `sudo nft add chain inet filter input { type filter hook input priority 0 \; policy accept \; }` |
| Rule | one match + action, top to bottom | `sudo nft add rule inet filter input tcp dport 5000 drop` |

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`, not inside the VM:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-030/module-01/lab-01
```

Four checks:

```text
FAIL  port-5000-drop
FAIL  port-6000-redirect
FAIL  port-6002-source-restriction
FAIL  egress-block
```

Run it now, then again after each step.

---

## Step 1: Look at the starting point

On the VM:

```bash
sudo nft list ruleset
```

It is empty. Confirm the redirect target is up:

```bash
sudo ss -tulpn | grep 6001
```

Something (a small Python web server) is listening on `6001`.

---

## Step 2: Create the filter table and its two chains

```bash
sudo nft add table inet filter
sudo nft add chain inet filter input '{ type filter hook input priority 0 ; policy accept ; }'
sudo nft add chain inet filter output '{ type filter hook output priority 0 ; policy accept ; }'
```

`type filter hook input` is what actually attaches the chain to incoming
traffic — a chain without a hook line is never consulted. `policy accept`
means "allow anything no rule explicitly drops".

*(No check flips yet — chains with no rules.)*

---

## Step 3: Drop inbound port 5000

```bash
sudo nft add rule inet filter input tcp dport 5000 drop
```

Check it:

```bash
sudo nft list chain inet filter input
```

**Run the check** — `port-5000-drop` now passes.

---

## Step 4: Restrict port 6002 to one source — accept first, then drop

Order matters. Add the **accept** rule first so it sits above the drop:

```bash
sudo nft add rule inet filter input tcp dport 6002 ip saddr 192.168.10.80 accept
sudo nft add rule inet filter input tcp dport 6002 drop
```

Verify the order — the accept line must appear before the drop line:

```bash
sudo nft -a list chain inet filter input
```

**Run the check** — `port-6002-source-restriction` now passes.

---

## Step 5: Block egress to 192.168.10.70

```bash
sudo nft add rule inet filter output ip daddr 192.168.10.70 drop
```

**Run the check** — `egress-block` now passes.

---

## Step 6: Create the NAT table and the redirect

The redirect lives in a separate `ip nat` table with a `prerouting` chain:

```bash
sudo nft add table ip nat
sudo nft add chain ip nat prerouting '{ type nat hook prerouting priority -100 ; policy accept ; }'
sudo nft add rule ip nat prerouting tcp dport 6000 redirect to :6001
```

`priority -100` (also called `dstnat`) is the standard priority for a
prerouting NAT chain. `redirect to :6001` rewrites the destination port to
`6001` on this same host.

Check it:

```bash
sudo nft list chain ip nat prerouting
```

**Run the check** — `port-6000-redirect` now passes. All four green.

---

## Step 7: Submit

When `astrona submit` shows all four `PASS`:

```text
PASS  port-5000-drop
PASS  port-6000-redirect
PASS  port-6002-source-restriction
PASS  egress-block
```

Submit from the host terminal:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-030/module-01/lab-01
```

> **Optional — make it stick.** These rules live only in the running
> kernel. To keep them after a reboot:
> `sudo nft list ruleset | sudo tee /etc/nftables.conf` then
> `sudo systemctl enable nftables`. Not required to pass this lab.

---

## If a check stays red

- **A rule was added but the check still fails.** The chain probably has no
  hook. Re-create it with the full
  `{ type filter hook input priority 0 ; policy accept ; }` form.
- **`port-6002-source-restriction` fails.** The drop is above the accept.
  Fix the order without wiping everything:
  `sudo nft flush chain inet filter input`, then re-add all four `input`
  rules from Steps 3–4 in order (5000 drop, 6002 accept, 6002 drop).
- **`port-6000-redirect` fails.** Check the rule reads exactly
  `tcp dport 6000 redirect to :6001` (with the colon) and that
  `sudo ss -tulpn | grep 6001` still shows a listener.
- **Everything is wrong and you want a clean slate.** `sudo nft flush
  ruleset` empties it, then start again from Step 2.
