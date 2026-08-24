# Solution

## Step 0: Confirm the interface name and current ruleset

```bash
ip -br link show
sudo nft list ruleset
```

Confirm the interface really is named `eth0` (some distros use predictable names like `enp0s3`) and see whether any base tables already exist — you don't want to accidentally create duplicate hooks with conflicting priorities.

## Step 1: Create a filter table with input and output chains

```bash
sudo nft add table inet filter
sudo nft add chain inet filter input   { type filter hook input priority filter\; policy accept\; }
sudo nft add chain inet filter output  { type filter hook output priority filter\; policy accept\; }
```

Check `man nft` and search for `hook` — the CHAINS section spells out the valid hook names per family (`input`, `output`, `forward`, `prerouting`, `postrouting`) and the valid named priorities, which is faster to confirm on the spot than guessing under exam pressure.

`inet` is a dual-stack table family (matches both IPv4 and IPv6) — the modern default unless you specifically need `ip`-only or `ip6`-only matching. `hook input` attaches to packets destined for this host; `hook output` attaches to packets originating from this host. `priority filter` (numeric `0`) places these chains at netfilter's conventional filtering point. `policy accept` is the default verdict for anything that falls through without matching a rule — we'll add explicit `drop` rules rather than flipping the whole chain to default-deny, since the task only asks for four specific behaviors, not a lockdown of the entire host.

## Step 2: Close port 5000

```bash
sudo nft add rule inet filter input iifname "eth0" tcp dport 5000 drop
```

`iifname "eth0"` scopes the rule to the interface named in the task — traffic arriving on other interfaces (e.g. loopback) is untouched. `tcp dport 5000` matches the TCP destination port. `drop` silently discards the packet with no response, which is what "closed" conventionally means in packet-filtering exam language (as opposed to `reject`, which sends back an ICMP/TCP-RST — either is defensible, but `drop` is the more common exam expectation for "closed").

## Step 3: Redirect port 6000 traffic to local port 6001

```bash
sudo nft add table ip nat
sudo nft add chain ip nat prerouting { type nat hook prerouting priority dstnat\; }
sudo nft add rule ip nat prerouting iifname "eth0" tcp dport 6000 redirect to :6001
```

Check `man nft` and search for `redirect` in the NAT STATEMENTS section — it documents `redirect` as shorthand for `dnat` to the machine's own address, and shows the `to :PORT` argument form.

Port redirection is destination NAT to *this same host*, so it must live in a `nat`-type table on the `prerouting` hook — this runs before routing decisions, which is exactly when a packet's destination port needs to change so the kernel subsequently delivers it to whatever's listening on 6001. The `redirect` statement is a convenience form of DNAT specifically for "redirect to a port on the local machine," which is simpler and more correct here than a manual `dnat to <local-ip>:6001` (redirect automatically uses whichever local address the packet arrived on, which matters if data-002 has multiple addresses). Note the `nat` table here uses family `ip` rather than `inet` — NAT chain types are not currently supported in `inet` family tables the same way filter chains are, so `ip` (IPv4-only) is the standard, portable choice for DNAT.

## Step 4: Restrict port 6002 to 192.168.10.80 only

```bash
sudo nft add rule inet filter input iifname "eth0" tcp dport 6002 ip saddr 192.168.10.80 accept
sudo nft add rule inet filter input iifname "eth0" tcp dport 6002 drop
```

This is the ordering principle from Study First made concrete: the `accept` rule for the trusted source IP is added *first*, and the catch-all `drop` for the same port is added *second*. `nft add rule` always appends to the end of the chain, so issuing these two commands in this order guarantees the correct evaluation order. If a connection to port 6002 arrives from 192.168.10.80, it matches the first rule and gets an `accept` verdict, which terminates chain evaluation — the second rule is never consulted for that packet. Any other source hitting port 6002 fails the first rule's `ip saddr` match, falls through to the second rule, and is dropped.

## Step 5: Block outgoing traffic to 192.168.10.70

```bash
sudo nft add rule inet filter output ip daddr 192.168.10.70 drop
```

This lives in the `output` chain because the task explicitly says "outgoing" — packets data-002 originates toward 192.168.10.70. No interface/port restriction was asked for, so this is a blanket destination-IP block for any protocol. (If the task later needed this scoped to `eth0` specifically, you'd add `oifname "eth0"` — using `output` alone already implies locally-originated traffic on whatever interface routes toward that destination.)

## Step 6: Review the full ruleset before persisting

```bash
sudo nft list ruleset
```

Read it top to bottom exactly as the kernel will evaluate it. Confirm the 6002 accept rule appears *before* the 6002 drop rule, and that each rule is attached to the chain/hook you intended.

## Step 7: Persist the ruleset across reboot

```bash
# Most distros: nft's own systemd unit reads a saved ruleset file at boot
sudo nft list ruleset | sudo tee /etc/nftables.conf
sudo systemctl enable --now nftables
```

nftables rules built with `nft add` live only in kernel memory — a reboot wipes them unless they're written to the file the `nftables.service` unit loads at boot (`/etc/nftables.conf` on Debian/Ubuntu and RHEL-family alike, though check `/etc/sysconfig/nftables.conf` or distro docs if it differs). Saving the ruleset and enabling the service is what makes this survive a restart, which matters both operationally and because exam grading sometimes reboots the target.

## Verification

```bash
sudo nft list ruleset
```

Expected (abbreviated):

```text
table inet filter {
        chain input {
                type filter hook input priority filter; policy accept;
                iifname "eth0" tcp dport 5000 drop
                iifname "eth0" tcp dport 6002 ip saddr 192.168.10.80 accept
                iifname "eth0" tcp dport 6002 drop
        }
        chain output {
                type filter hook output priority filter; policy accept;
                ip daddr 192.168.10.70 drop
        }
}
table ip nat {
        chain prerouting {
                type nat hook prerouting priority dstnat; policy accept;
                iifname "eth0" tcp dport 6000 redirect to :6001
        }
}
```

Functional checks (run from data-001, IP 192.168.10.80, where relevant):

```bash
# From data-001: port 6002 should succeed (or at least not be firewall-blocked)
nc -zv 192.168.10.?? 6002

# From any other host: port 6002 should time out / be refused
nc -zv 192.168.10.?? 6002

# Port 5000 should never connect from anywhere
nc -zv 192.168.10.?? 5000

# A connection to 6000 should land on whatever is listening on 6001
nc -zv 192.168.10.?? 6000
```

On data-002 itself, confirm no outbound reachability to app-srv1:

```bash
ping -c1 192.168.10.70   # should get no reply once the output rule is active
```

## Command Summary

```bash
ip -br link show
sudo nft list ruleset

sudo nft add table inet filter
sudo nft add chain inet filter input   { type filter hook input priority filter\; policy accept\; }
sudo nft add chain inet filter output  { type filter hook output priority filter\; policy accept\; }
sudo nft add rule inet filter input iifname "eth0" tcp dport 5000 drop

sudo nft add table ip nat
sudo nft add chain ip nat prerouting { type nat hook prerouting priority dstnat\; }
sudo nft add rule ip nat prerouting iifname "eth0" tcp dport 6000 redirect to :6001

sudo nft add rule inet filter input iifname "eth0" tcp dport 6002 ip saddr 192.168.10.80 accept
sudo nft add rule inet filter input iifname "eth0" tcp dport 6002 drop

sudo nft add rule inet filter output ip daddr 192.168.10.70 drop

sudo nft list ruleset
sudo nft list ruleset | sudo tee /etc/nftables.conf
sudo systemctl enable --now nftables
```
