# Question

Solve this question on: `target`

## Scenario

This is the Section 020 capstone — one integrated static-routing task,
no step-by-step guidance.

This environment has two machines. You work on **`target`**. It sits on
`backend-net` (`10.10.20.0/24`) with the address `10.10.20.5`.

A partner subnet, `10.10.30.0/24`, lives behind the other machine
(`gateway`), which is reachable at `10.10.20.1` and is already forwarding.
`target` currently has **no route** to that partner subnet — traffic for
`10.10.30.0/24` has nowhere to go.

## Tasks

On `target`:

1. **Add the route.** Give `target` a route to `10.10.30.0/24` with next hop
   `10.10.20.1`. After this:
   - `ip route show 10.10.30.0/24` shows the route `via 10.10.20.1`,
   - `ip route get 10.10.30.1` selects `via 10.10.20.1`, and
   - `ping 10.10.30.1` gets replies (the gateway forwards them).

2. **Persistence.** Declare that same route — destination `10.10.30.0/24`,
   gateway `10.10.20.1` — in on-disk network configuration (a file under
   `/etc/netplan/`, a systemd-networkd `.network` file, a NetworkManager
   connection, or a legacy `route-` file) so it is restored on reboot. A
   route added only with `ip route add` does not count.
