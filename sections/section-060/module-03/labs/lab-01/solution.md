# Solution Walkthrough

You will confirm the service is listening, find the `nftables` rule that
drops port `8080`, delete it, and prove the application answers. Everything
runs on the lab virtual machine's `terminal`, except grading.

Work down this ladder of questions for any "service unreachable" problem:

| Question | Tool |
| --- | --- |
| Is anything listening, and on what address? | `sudo ss -tulpn` |
| Is a firewall dropping it? | `sudo nft list ruleset` |
| Does it work end to end now? | `curl http://127.0.0.1:8080/` |

## The feedback loop

Grading runs from your **own terminal**: the shell where you typed
`astrona run`:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-060/module-03/labs/lab-01
```

There are three checks:

```text
PASS  listening
FAIL  nftables
FAIL  http-reachable
```

`listening` already passes, because the application is bound to
`0.0.0.0:8080`. Run the check again after you fix the rule.

---

## Step 1: Confirm the listener

`ss` lists the open sockets: the roster of every open radio channel and the
process that holds it.

```bash
sudo ss -tulpn | grep 8080
```

You should see a `LISTEN` line for `0.0.0.0:8080` owned by `python3`. That
is `myapp`. The application is fine, so do not touch it.

---

## Step 2: Confirm the traffic is dropped

Ask the application for its page, and give up after 5 seconds:

```bash
curl -m 5 http://127.0.0.1:8080/
```

It hangs and times out. Now look at the firewall. nftables is the console
you use to program the kernel's shields:

```bash
sudo nft list ruleset
```

Inside `table inet filter`, in `chain input`, you will see this line:

```text
tcp dport 8080 drop
```

That is the block.

You can also watch it happen. Run `sudo tcpdump -ni any tcp port 8080` in
one shell, then run `curl` again in another. You see the incoming SYN and no
reply: the kernel drops the packet before the application ever sees it.

---

## Step 3: Delete the rule

nftables deletes rules by **handle**, a number it gives every rule. Print the
handles:

```bash
sudo nft -a list chain inet filter input
```

Each rule line now ends with `# handle N`. Find the `tcp dport 8080 drop`
line, note its number, then delete it:

```bash
sudo nft delete rule inet filter input handle N
```

Replace `N` with the real handle. Confirm the rule is gone:

```bash
sudo nft list ruleset | grep 8080 || echo "no 8080 rule"
```

**Run the check**. `nftables` now passes.

---

## Step 4: Prove the service answers

```bash
curl http://127.0.0.1:8080/
```

You should get the application's HTML back at once.

**Run the check**. `http-reachable` now passes, and all three checks are
green.

---

## Step 5: Make the fix stick, then submit

The setup script wrote the broken ruleset to `/etc/nftables.conf`, so the
block would come back after a reboot. Save the fixed ruleset over it:

```bash
sudo nft list ruleset | sudo tee /etc/nftables.conf
```

Then submit from your own terminal:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-060/module-03/labs/lab-01
```

---

## If a check stays red

- **`nftables` still fails.** You deleted the wrong handle, or there is more
  than one matching rule. Run `sudo nft -a list chain inet filter input`
  again and delete every `tcp dport 8080 drop` line by its handle. As a last
  resort, `sudo nft flush chain inet filter input` empties that chain.
- **`http-reachable` fails but `nftables` passes.** Something else is
  blocking. Look for a second table or chain with an 8080 rule
  (`sudo nft list ruleset`), and check that `myapp` is still running
  (`systemctl status myapp`).
- **`listening` fails.** You restarted `myapp` bound to loopback only. It
  must listen on `0.0.0.0:8080`; `sudo systemctl restart myapp` brings back
  the unit the setup script installed.
