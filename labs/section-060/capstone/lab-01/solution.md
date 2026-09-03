# Solution Walkthrough

You will confirm the service is listening, find the `nftables` rule that
drops port `8080`, delete it, and prove the app is reachable. Everything
runs on the VM's `terminal`.

The diagnostic ladder for "service unreachable":

| Question | Tool |
| --- | --- |
| Is anything listening, and on what address? | `sudo ss -tulpn` |
| Is a firewall dropping it? | `sudo nft list ruleset` |
| Does it work end to end now? | `curl http://127.0.0.1:8080/` |

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`:

```bash
astrona test -c labs/section-060/capstone/lab-01
```

Three checks:

```text
PASS  listening
FAIL  nftables
FAIL  http-reachable
```

`listening` already passes (the app is bound to `0.0.0.0:8080`). Run the
check again after fixing the rule.

---

## Step 1: Confirm the listener

```bash
sudo ss -tulpn | grep 8080
```

You should see a `LISTEN` line for `0.0.0.0:8080` owned by `python3`
(that is `myapp`). Good — the app is fine. Do not touch it.

---

## Step 2: Confirm the traffic is dropped

```bash
curl -m 5 http://127.0.0.1:8080/
```

It hangs and times out. Now look at the firewall:

```bash
sudo nft list ruleset
```

You will see, inside `table inet filter` / `chain input`, a line:

```text
tcp dport 8080 drop
```

That is the block.

*(Optional — watch it happen: run `sudo tcpdump -ni any tcp port 8080` in
one shell, then `curl` again in another. You see the incoming SYN and no
reply — the packet is dropped before the app ever sees it.)*

---

## Step 3: Delete the rule

nftables deletes rules by **handle**. Print the handles:

```bash
sudo nft -a list chain inet filter input
```

Each rule line now ends with `# handle N`. Find the `tcp dport 8080 drop`
line and note its number, then delete it:

```bash
sudo nft delete rule inet filter input handle N
```

(Replace `N` with the real handle.) Confirm it is gone:

```bash
sudo nft list ruleset | grep 8080 || echo "no 8080 rule"
```

**Run the check** — `nftables` now passes.

---

## Step 4: Prove reachability

```bash
curl http://127.0.0.1:8080/
```

You should get the app's HTML back immediately.

**Run the check** — `http-reachable` now passes. All three green.

---

## Step 5: Make the fix stick, then submit

The setup wrote the broken ruleset to `/etc/nftables.conf`, so it would come
back on reboot. Re-save the good ruleset:

```bash
sudo nft list ruleset | sudo tee /etc/nftables.conf
```

Then submit from the host terminal:

```bash
astrona submit -c labs/section-060/capstone/lab-01
```

---

## If a check stays red

- **`nftables` still fails.** You deleted the wrong handle, or there is more
  than one matching rule. Re-run `sudo nft -a list chain inet filter input`
  and delete every `tcp dport 8080 drop` line by handle. As a last resort,
  `sudo nft flush chain inet filter input` clears that chain entirely.
- **`http-reachable` fails but `nftables` passes.** Something else is
  blocking — check for a second table/chain with an 8080 rule
  (`sudo nft list ruleset`), and confirm `myapp` is still up
  (`systemctl status myapp`).
- **`listening` fails.** You restarted `myapp` with a loopback bind. It must
  listen on `0.0.0.0:8080`; `sudo systemctl restart myapp` restores the
  bootstrap unit.
