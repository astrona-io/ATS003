# Solution

## Step 1: Locate the chrony configuration file

```bash
# Ubuntu/Debian
ls /etc/chrony/chrony.conf

# RHEL/Fedora/openSUSE
ls /etc/chrony.conf
```

Debian-family distros ship chrony's config at `/etc/chrony/chrony.conf`; RHEL-family distros use `/etc/chrony.conf` directly. Both are read by the same `chronyd` daemon and use identical directive syntax — only the path differs. Back the file up before editing:

```bash
sudo cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak
```

Check `man 5 chrony.conf` — the entries for `server` and `pool` sit right next to each other and spell out exactly which options (`iburst`, `maxpoll`, `minpoll`, `prefer`) each one accepts, which is faster than guessing from memory under exam pressure.

## Step 2: Understand `server` vs `pool`

```conf
# server: one specific NTP host
server 0.pool.ntp.org iburst

# pool: a DNS name that resolves to *multiple* rotating hosts
pool 1.pool.ntp.org iburst maxsources 4
```

`pool.ntp.org` addresses are round-robin DNS names backed by many volunteer servers, so chrony is told to treat them as a pool and pick several distinct hosts behind the name. A plain `server` line is a single fixed host. The task names four *.pool.ntp.org-style hostnames, so `pool` is the technically correct directive for all of them, though `server` also works functionally (chrony will just resolve one A/AAAA record from the pool name rather than diversifying). Using `pool` here is more correct because it matches what these hostnames are designed for.

## Step 3: Configure the main NTP servers

Edit the config and remove any existing `pool`/`server` lines that conflict, then add:

```conf
# Main time sources
pool 0.pool.ntp.org iburst maxpoll 10
pool 1.pool.ntp.org iburst maxpoll 10
```

- `iburst` tells chrony to send a burst of closely-spaced probe packets when a source is first contacted (or after an outage), instead of waiting a full poll interval for the first reachability data — this dramatically speeds up initial sync, which matters right after a reload or boot.
Check `man 5 chrony.conf` and search for `maxpoll` — the description explicitly states the argument is "the maximum interval... in seconds, but expressed as a power of 2" — this is exactly the kind of exact wording you can only get by reading the page, not by recalling a number.

- `maxpoll 10` sets the maximum polling interval as `2^10 = 1024` seconds — the closest supported power-of-two to the requested 1000 seconds. There is no way to set an arbitrary non-power-of-two interval; chrony's poll interval is always expressed as an exponent of two by design (this bounds the polling algorithm's step size). `maxpoll 10` (1024s) is the honest, defensible answer to "maximum poll interval should be 1000 seconds" since 1000 itself is not achievable exactly.

## Step 4: Configure the fallback NTP servers

```conf
# Fallback time sources
server ntp.ubuntu.com iburst maxpoll 10
server 0.debian.pool.ntp.org iburst maxpoll 10
```

There is no chrony keyword that literally means "only use this if the main ones fail." chrony's source-selection algorithm continuously scores every configured source on stratum, root distance, and jitter, and always picks the statistically best one(s) — all configured sources are active candidates simultaneously. The realistic way to express "these are fallback/less-preferred sources" is to leave the main pool servers with default preference (or add `prefer` to them) and let chrony's own selection algorithm naturally favor the lower-jitter, lower-stratum main sources unless they become unreachable, at which point chrony automatically promotes the next best source — which is exactly the *behavior* the task is asking for, just achieved through chrony's normal selection logic rather than a named "fallback" flag.

If you want to make the preference explicit and auditable, mark the main servers with `prefer`:

```conf
pool 0.pool.ntp.org iburst maxpoll 10 prefer
pool 1.pool.ntp.org iburst maxpoll 10 prefer
server ntp.ubuntu.com iburst maxpoll 10
server 0.debian.pool.ntp.org iburst maxpoll 10
```

`prefer` tells chrony's mitigation algorithm to favor these sources when multiple sources are otherwise close in quality, which is the closest real, documented approximation of "main" vs "fallback."

## Step 5: The "connection retry 20 seconds" requirement

Run `man -k poll` or search `man 5 chrony.conf` for "retry" first — you'll find no match, which is itself useful confirmation that this phrase does not map to any literal chrony directive; chrony has no setting named `retry`. The two real knobs in this space are:

- `minpoll` — the *shortest* interval (again as a power-of-two exponent) chrony will use when a source needs more frequent measurement, e.g. right after startup or when jitter is high.
- chrony's internal unreachable-source retry behavior, which is not user-configurable as a flat "N seconds" value — it is driven by the poll interval back-off/recovery algorithm itself.

The defensible, honest configuration is to set `minpoll` to the exponent closest to 20 seconds. `2^4 = 16` and `2^5 = 32`; 16 is the closer power of two to 20:

```conf
pool 0.pool.ntp.org iburst minpoll 4 maxpoll 10 prefer
pool 1.pool.ntp.org iburst minpoll 4 maxpoll 10 prefer
server ntp.ubuntu.com iburst minpoll 4 maxpoll 10
server 0.debian.pool.ntp.org iburst minpoll 4 maxpoll 10
```

Document this reasoning inline as a config comment so a reviewer (or future you) understands why 20 became `minpoll 4`:

```conf
# minpoll 4 (16s) approximates the requested 20s minimum re-check interval;
# chrony has no literal "connection retry" directive — minpoll is the
# closest real mechanism for how soon a source is re-polled.
```

## Step 6: Validate and reload

```bash
# Syntax/sanity check without touching the running daemon
sudo chronyd -Q -f /etc/chrony/chrony.conf 'server 0.pool.ntp.org iburst' 2>&1 | head -5

# Restart the running daemon to pick up the edited file
sudo systemctl restart chrony
```

Some chrony builds don't support a live `reload` for source changes and need a `restart`; if `reload` errors or silently doesn't pick up new sources, `restart` is the safe fallback — it's a short daemon blip, not a service that anything else depends on synchronously.

## Step 7: Confirm with chronyc

```bash
chronyc sources -v
```

The symbol in the leftmost column tells you the source's role in the current selection: `*` is the currently synced-to source, `+` is a acceptable candidate also being combined into the estimate, `?` means unreachable, `x` means a falseticker excluded by the algorithm.

```bash
chronyc tracking
```

`Stratum`, `Reference ID`, and `System time` offset here prove chrony is actually disciplining the clock, not merely configured to try.

## Verification

```bash
chronyc sources
```

Expected output (four sources, all reachable eventually — reachability register fills in over the next few polls):

```text
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* pool-a.ntp.org                 2  10   377    45   -123us[ -200us] +/-   12ms
^+ pool-b.ntp.org                 2  10   377    50   +456us[ +400us] +/-   15ms
^? ntp.ubuntu.com                 3   4     0     -     +0ns[   +0ns] +/-    0ns
^? 0.debian.pool.ntp.org          2   4     0     -     +0ns[   +0ns] +/-    0ns
```

```bash
chronyc tracking
```

```text
Reference ID    : XXXXXXXX (pool-a.ntp.org)
Stratum         : 3
Ref time (UTC)  : ...
System time     : 0.000123456 seconds fast of NTP time
Leap status     : Normal
```

`Leap status: Normal` and a populated `Reference ID` confirm chrony has locked onto a source, not just started up.

## Command Summary

```bash
sudo cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak
sudo $EDITOR /etc/chrony/chrony.conf
# add:
#   pool 0.pool.ntp.org iburst minpoll 4 maxpoll 10 prefer
#   pool 1.pool.ntp.org iburst minpoll 4 maxpoll 10 prefer
#   server ntp.ubuntu.com iburst minpoll 4 maxpoll 10
#   server 0.debian.pool.ntp.org iburst minpoll 4 maxpoll 10
sudo systemctl reload chrony || sudo systemctl restart chrony
chronyc sources -v
chronyc tracking
timedatectl status
```
