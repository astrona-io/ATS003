# Question

Solve this question on: `terminal`

## Scenario

This mission has two training ships flying in formation. You work on **`target`**. It sits on the segment `backend-net` (`10.10.20.0/24`) with the address `10.10.20.5`.

A partner subnet, `10.10.30.0/24`, lies behind the other machine, **`gateway`**: a relay ship at `10.10.20.1` that already forwards traffic. Right now `target` has **no route** to that partner subnet, so traffic for `10.10.30.0/24` has no lane on its star chart.

## Tasks

Do all the work on `target`. You do not need to change anything on `gateway`.

1. **Add the route.** Give `target` a route to `10.10.30.0/24` with the next hop `10.10.20.1`. After this:
   - `ip route show 10.10.30.0/24` shows the route `via 10.10.20.1`,
   - `ip route get 10.10.30.1` selects `via 10.10.20.1`, and
   - `ping 10.10.30.1` gets replies, because the gateway forwards them.

2. **Persistence.** Declare that same route, destination `10.10.30.0/24` with gateway `10.10.20.1`, in on-disk network configuration, so it comes back after a reboot. Any of these counts: a file under `/etc/netplan/`, a `systemd-networkd` `.network` file, a NetworkManager connection, or a legacy `route-` file. A route added only with `ip route add` does not count.
