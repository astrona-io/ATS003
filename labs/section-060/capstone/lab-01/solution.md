# Solution

## Step 1: Confirm the process is actually listening

```bash
sudo ss -tulpn | grep 8080
```

Check `man ss` — `-t` (TCP), `-u` (UDP), `-l` (listening sockets only), `-p` (show owning process, needs privilege), `-n` (numeric ports, skip slow name resolution) is the combination that answers "what's listening and what owns it" in one shot. Expected output if the app is up and correctly bound:

```text
tcp   LISTEN  0  511  0.0.0.0:8080  0.0.0.0:*  users:(("myapp",pid=1234,fd=6))
```

If this returns nothing at all, the application isn't running or crashed — that's the root cause right there, no need to go further into firewall/packet-capture territory. If it shows `127.0.0.1:8080` instead of `0.0.0.0:8080` (or a specific reachable interface IP), that's also a complete, sufficient explanation — the socket is bound to loopback only and structurally can't accept remote connections, independent of any firewall rule.

For this scenario, assume `ss` confirms the process is correctly listening on `0.0.0.0:8080` — so the problem lies further out.

## Step 2: Sanity-check addressing and routing

```bash
ip addr show
ip route show
```

Quick confirmation that web-srv1's own addressing hasn't silently changed and that its routing table looks sane — cheap to check early and rules out an entire category of "the network changed under me" problems before diving into firewall/packet-level detail.

## Step 3: Check the firewall ruleset

```bash
sudo nft list ruleset
```

Check `man nft` (CHAINS section) if the hook/priority syntax in the output is unfamiliar. Read the `input` chain top to bottom looking specifically for anything matching port 8080:

```text
table inet filter {
        chain input {
                type filter hook input priority filter; policy accept;
                tcp dport 8080 drop
        }
}
```

A `tcp dport 8080 drop` rule here is a complete, sufficient explanation for "unreachable" even though the application is correctly listening — the kernel's netfilter hook discards the packet before it ever reaches the socket. This is the root cause in this scenario.

## Step 4: Confirm the diagnosis with a live packet capture

Even once you spot the likely rule, capturing traffic proves it rather than assuming — this habit generalizes to firewall problems that aren't as obviously visible as a single `drop` line (e.g. buried in a longer chain, or a `nat` table redirect gone wrong).

```bash
sudo tcpdump -i eth0 port 8080 -n
```

Check `man tcpdump` (EXPRESSIONS section) — `port 8080` is a primitive that matches either source or destination port 8080; `-i eth0` scopes the capture to the relevant interface; `-n` disables reverse-DNS lookups so the capture doesn't stall waiting on name resolution for every packet.

From a remote host, attempt a connection while the capture runs:

```bash
# on a remote client, e.g. app-srv1
nc -zv 192.168.10.60 8080
```

Expected capture output if the firewall is dropping the packet (the diagnosis in this scenario):

```text
12:00:01.123456 IP 192.168.10.70.51234 > 192.168.10.60.8080: Flags [S], seq 123456789, win 64240, length 0
```

Only the inbound SYN appears — no corresponding `Flags [S.]` (SYN-ACK) response ever leaves web-srv1 in the capture. Combined with Step 1's confirmation that something is genuinely listening on that port, a SYN with no SYN-ACK response is the packet-level signature of a firewall drop, not a missing listener (which would look identical at this layer, which is exactly why Step 1 had to come first — the capture alone can't distinguish "nothing's listening" from "firewall is dropping it").

## Step 5: Fix the nftables rule

```bash
sudo nft -a list ruleset
```

Check `man nft` for the `-a` flag (show rule handles) — you need the handle number to remove the specific rule precisely, rather than flushing the whole chain and losing unrelated rules.

```text
table inet filter {
        chain input { # handle 1
                type filter hook input priority filter; policy accept;
                tcp dport 8080 drop # handle 4
        }
}
```

```bash
sudo nft delete rule inet filter input handle 4
```

If port 8080 should instead be explicitly allowed (rather than just un-blocked, e.g. because a broader default-deny policy exists elsewhere in the chain), add an explicit accept instead of only deleting the drop:

```bash
sudo nft add rule inet filter input tcp dport 8080 accept
```

Persist the fix the same way any nftables change must be persisted:

```bash
sudo nft list ruleset | sudo tee /etc/nftables.conf
```

## Step 6: Re-verify at the same layer you diagnosed the break

```bash
sudo tcpdump -i eth0 port 8080 -n -c 4
```

From the remote client again:

```bash
nc -zv 192.168.10.60 8080
```

Expected capture now shows the full three-way handshake:

```text
12:05:01.111111 IP 192.168.10.70.51240 > 192.168.10.60.8080: Flags [S], seq ..., win 64240, length 0
12:05:01.111150 IP 192.168.10.60.8080 > 192.168.10.70.51240: Flags [S.], seq ..., ack ..., win 65160, length 0
12:05:01.111200 IP 192.168.10.70.51240 > 192.168.10.60.8080: Flags [.], ack ..., win 502, length 0
```

The `Flags [S.]` (SYN-ACK) line appearing this time is the proof the fix worked at exactly the layer where the original problem was diagnosed — stronger evidence than trusting the config change alone.

## Verification

```bash
sudo ss -tulpn | grep 8080
```

```text
tcp   LISTEN  0  511  0.0.0.0:8080  0.0.0.0:*  users:(("myapp",pid=1234,fd=6))
```

```bash
sudo nft list ruleset | grep -A3 'chain input'
```

No `tcp dport 8080 drop` line remaining, and (if added) an explicit `tcp dport 8080 accept` present.

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.10.60:8080/
```

Expected: a real HTTP status code (e.g. `200`) instead of a connection timeout/refusal.

## Command Summary

```bash
sudo ss -tulpn | grep 8080
ip addr show
ip route show

sudo nft list ruleset
sudo nft -a list ruleset

sudo tcpdump -i eth0 port 8080 -n
# (from remote client) nc -zv 192.168.10.60 8080

sudo nft delete rule inet filter input handle 4
sudo nft add rule inet filter input tcp dport 8080 accept
sudo nft list ruleset | sudo tee /etc/nftables.conf

sudo tcpdump -i eth0 port 8080 -n -c 4
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.10.60:8080/
```
