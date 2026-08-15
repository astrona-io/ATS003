# Solution

## Step 1: Confirm `data-001`'s existing client configuration

```bash
# Ubuntu/Debian
cat /etc/chrony/chrony.conf | grep -E '^(server|pool)'
```

This should already show `data-001` syncing from the public pool (per the existing client lab's pattern) — that part doesn't change; `data-001` continues being a client of the public pool while also becoming a server for the internal subnet. Both roles coexist in the same config file.

## Step 2: Add the `allow` directive to permit the internal subnet

```conf
# /etc/chrony/chrony.conf on data-001

# existing client sources (unchanged)
pool 0.pool.ntp.org iburst
pool 1.pool.ntp.org iburst

# NEW: serve time to the internal data-tier subnet
allow 192.168.10.0/24
```

Check `man 5 chrony.conf` and search `/allow` — the directive is documented as taking a subnet (CIDR) or a single address, and the page states plainly that with no `allow` line at all, `chronyd` responds to no client NTP requests whatsoever. This single line is the entire difference between "chrony running, but client-only" and "chrony also acting as a server" — there's no separate `server_mode yes`-style toggle.

`allow` can be scoped as tightly or broadly as needed — `allow 192.168.10.0/24` permits the whole internal subnet in one line; a narrower deployment could list individual host IPs with multiple `allow` lines instead.

## Step 3: Restart chrony to apply the new directive

```bash
sudo systemctl restart chrony
```

As in the client lab, some chrony builds don't reliably pick up structural config changes via `reload` — `restart` is the safe choice here since `allow` changes chronyd's listening/answering behavior, not just its source list.

## Step 4: Confirm `data-001` itself is synced before relying on it as a source for others

```bash
chronyc tracking
```

Check the `Stratum` field in the output — `data-001` needs to actually be synced (`Leap status: Normal`, a sane `Stratum` value) before anything downstream can usefully sync from it; a not-yet-synced server will simply report itself as unsynchronized to anyone querying it (stratum 16, chrony's conventional "not synchronized" value).

## Step 5: Open the firewall for inbound NTP if one is active on `data-001`

```bash
# nftables example
sudo nft add rule inet filter input ip saddr 192.168.10.0/24 udp dport 123 accept
```

NTP uses UDP port 123 for both client and server traffic. If `data-001` runs a host firewall (nftables/iptables/firewalld), an inbound rule permitting UDP/123 from the internal subnet is required or every query from `app-srv1` and the other hosts will simply time out with no response, indistinguishable at first glance from a misconfigured `allow` line. Check with the firewall tool actually in use on the host before assuming this step is needed — a lab image with no active firewall doesn't need it at all.

## Step 6: Point `app-srv1` at `data-001` instead of the public pool

On the client VM (`app-srv1`'s role):

```bash
sudo cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak
```

```conf
# /etc/chrony/chrony.conf on app-srv1

# was: pool 0.pool.ntp.org iburst  (and similar) — remove these
server astrona-ats-003-lab-090-server iburst
```

This is the identical `server ... iburst` syntax from the client lab — nothing new to learn syntactically, just pointing the hostname argument at `data-001`'s internal address (in this lab, the server VM, reachable as `astrona-ats-003-lab-090-server`) instead of a public pool name. `server` (not `pool`) is the right directive here because `data-001` is one specific fixed host, not a round-robin DNS name resolving to many hosts the way `*.pool.ntp.org` does. Remove the old public pool lines rather than leaving them alongside — the task says "instead of," not "in addition to."

```bash
sudo systemctl restart chrony
```

## Verification

On `data-001` (server side) — confirm clients are actually querying it:

```bash
chronyc clients
```

```text
Hostname                      NTP   Drop Int IntL Last     Cmd   Drop Int  Last
===============================================================================
app-srv1                       12      0  10   -     32       0      0   -
```

A nonzero `NTP` request count for `app-srv1` proves it's actively querying `data-001` as a time source — this is the definitive proof server mode is working, from the server's own perspective.

On `app-srv1` (client side) — confirm it's synced against `data-001` and check the resulting stratum:

```bash
chronyc sources -v
```

```text
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* astrona-ats-003-lab-090-server 3  10   377    45   -50us[  -80us] +/-  8ms
```

```bash
chronyc tracking
```

```text
Reference ID    : C0A80A50 (astrona-ats-003-lab-090-server)
Stratum         : 4
Leap status     : Normal
```

`Stratum : 4` on `app-srv1` while `data-001` itself is stratum 3 confirms the expected one-hop increment — `app-srv1` is exactly one stratum further from the reference clock than the internal server it's syncing from.

## Command Summary

```bash
# data-001 (server role)
cat /etc/chrony/chrony.conf | grep -E '^(server|pool)'
sudo $EDITOR /etc/chrony/chrony.conf
# add: allow 192.168.10.0/24
sudo systemctl restart chrony
chronyc tracking
sudo nft add rule inet filter input ip saddr 192.168.10.0/24 udp dport 123 accept
chronyc clients

# app-srv1 (client role)
sudo cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak
sudo $EDITOR /etc/chrony/chrony.conf
# replace pool lines with: server astrona-ats-003-lab-090-server iburst
sudo systemctl restart chrony
chronyc sources -v
chronyc tracking
```
