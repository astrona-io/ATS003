# Question

Solve this question on: `server` and `client`

## Scenario

Astronaut, this mission has two training ships: `server` and `client`. You work on both. `server` should become the internal Network Time Protocol (NTP) server, the time beacon for the `192.168.10.0/24` subnet, and `client` should sync from `server` instead of the public pool. `chrony` is installed and running on both, each with a default `/etc/chrony/chrony.conf`.

## Tasks

### On `server`

1. **Enable server mode for the subnet.** Add an active `allow 192.168.10.0/24` line to `/etc/chrony/chrony.conf` and restart `chrony`. After that:
   - `chronyd` is listening on User Datagram Protocol (UDP) port `123`,
   - `chronyc serverstats` runs and reports NTP packet counters, and
   - the server itself is synced (`chronyc tracking`: `Leap status : Normal`, stratum 1 to 15).

### On `client`

2. **Point the client at the internal server.** In `/etc/chrony/chrony.conf`, replace the public pool and server lines with a single source: `server 192.168.10.123 iburst`. No public `pool`, `pool.ntp.org` or `ntp.ubuntu.com` lines may remain active.

3. **Sync through it.** Restart `chrony`. `chronyc sources` must show `192.168.10.123` as the currently selected source (`^*`), with `Leap status : Normal` and a stratum one hop above the server (2 to 15).

## The isolated training clock

The server starts with `local stratum 10`. This lets the private network exercise run without depending on public NTP traffic. It demonstrates client/server synchronization, but does not establish accurate UTC time. In production, configure reliable upstream sources instead of treating a local clock as authoritative. The client should select `192.168.10.123` and report stratum 11.
