# Question

Solve this question on: `terminal`

## Scenario

Astronaut, this ship's clockmaster needs a fixed list of time beacons with tuned poll limits. `chrony` is installed and running with its default `/etc/chrony/chrony.conf`. Rewrite the source list to the four servers below, restart chrony so it reads the new file, and confirm it is correcting the clock.

## Tasks

Edit `/etc/chrony/chrony.conf` so that:

1. **These four time sources are configured** (as `server` lines):
   - `0.pool.ntp.org`
   - `1.pool.ntp.org`
   - `ntp.ubuntu.com`
   - `0.debian.pool.ntp.org`

   Remove or comment out any existing `pool` or `server` lines that are not in this list, so chrony uses only these four.

2. **Every one of those four lines sets `minpoll 4` and `maxpoll 10`.** The values are powers of two seconds: poll no more often than every 16 seconds and no less often than every 1024 seconds. They are the closest powers of two to a 20-second retry and a 1000-second ceiling.

3. **`chronyd` runs with the new file and is synchronised:** `chronyc tracking` reports `Leap status : Normal`.
