# Question

Solve this question on: `terminal`

## Scenario

This host's time sync needs a defined set of sources with tuned poll
intervals. `chrony` is installed and running with its default
`/etc/chrony/chrony.conf`. Rewrite the source list to the four servers
below, then reload the daemon and confirm it is disciplining the clock.

## Tasks

Edit `/etc/chrony/chrony.conf` so that:

1. **These four time sources are configured** (as `server` lines):
   - `0.pool.ntp.org`
   - `1.pool.ntp.org`
   - `ntp.ubuntu.com`
   - `0.debian.pool.ntp.org`

   Any pre-existing `pool` / `server` lines that are not in this list must
   be removed or commented out (the check reads the *first* line for a
   given host).

2. **Every one of those four lines sets `minpoll 4` and `maxpoll 10`** —
   poll no faster than every 16 s, no slower than every ~1024 s (the
   closest powers of two to a 20 s retry and a 1000 s ceiling).

3. **`chronyd` has reloaded the new config and is synchronised** —
   `chronyc tracking` reports `Leap status : Normal`.
