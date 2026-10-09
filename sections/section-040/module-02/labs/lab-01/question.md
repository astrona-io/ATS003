# Question

Solve this question on: `terminal`

## Scenario

Astronaut, this mission has two training ships: `server` and `client`. You work on both. `server` should become the internal Network Time Protocol (NTP) server, the time beacon for the `192.168.10.0/24` subnet, and `client` should sync from `server` instead of the public pool. `chrony` is installed and running on both, each with a default `/etc/chrony/chrony.conf`.

## Tasks

### On `server`

1. **Enable server mode for the subnet.** Add an active `allow 192.168.10.0/24` line to `/etc/chrony/chrony.conf` and restart `chrony`. After that:
   - `chronyd` is listening on User Datagram Protocol (UDP) port `123`,
   - `chronyc serverstats` runs and reports NTP packet counters, and
   - the server itself is synced (`chronyc tracking`: `Leap status : Normal`, stratum 1 to 15).

### On `client`

2. **Point the client at the internal server.** In `/etc/chrony/chrony.conf`, replace the public pool and server lines with a single source: `server astrona-ats-003-lab-042-server iburst`. No public `pool`, `pool.ntp.org` or `ntp.ubuntu.com` lines may remain active.

3. **Sync through it.** Restart `chrony`. `chronyc sources` must show `astrona-ats-003-lab-042-server` as the currently selected source (`^*`), with `Leap status : Normal` and a stratum one hop above the server (2 to 15).
