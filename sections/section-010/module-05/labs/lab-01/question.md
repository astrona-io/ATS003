# Question

Solve this question on: `terminal`

## Scenario

Astronaut, a DHCP server answers on the antenna `dhcpsrv0` (`10.77.0.1/24`). It hands out addresses from `10.77.0.100` to `10.77.0.149`, and it also offers a router and a DNS server. Your client antenna `dhcp0` is linked to it and has no configuration.

You need the call sign from the lease, but the ship must keep its current default route and must not use the DNS server from the lease. Do not touch the management interface or its Netplan file.

## Tasks

1. **Write the Netplan file.** Create a new file in `/etc/netplan/` that turns on `dhcp4` for `dhcp0` and sets `use-routes: false` and `use-dns: false` under `dhcp4-overrides`. Apply it with `sudo netplan apply`.

2. **Get the lease.** `dhcp0` must hold an IPv4 address between `10.77.0.100` and `10.77.0.149` that came from DHCP.

3. **Keep the default lane.** No default route may use `dhcp0`, and the existing default route must stay as it was.

4. **Refuse the directory.** `resolvectl dns dhcp0` must list no server.

The grader reads the Netplan files, `ip` output and `resolvectl`.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-05](../../course.md).

The grader checks:

- Confirms a Netplan file enables dhcp4 for dhcp0 with use-routes false and use-dns false.
- Confirms dhcp0 holds an address from 10.77.0.100-149 obtained by DHCP.
- Confirms no default route uses dhcp0 and the management default route is unchanged.
- Confirms systemd-resolved holds no DNS server for dhcp0.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
