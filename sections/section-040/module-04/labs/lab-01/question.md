# Question

Solve this question on: `terminal`

## Scenario

Astronaut, a DNS server for the zone `lab.example` answers on `10.55.0.53`. It knows `www`, `db` and `app` in that zone. The resolver on this ship (`systemd-resolved`) was never told about it, so these names do not resolve. Fix that for the whole ship, and make the fix survive a restart of the resolver.

Do not edit `/etc/resolv.conf` and do not touch the management interface.

## Tasks

1. **Teach the resolver.** Create a drop-in file in `/etc/systemd/resolved.conf.d/` that sets `DNS=10.55.0.53` and `Domains=lab.example`. Restart `systemd-resolved` so that `resolvectl status` shows the server.

2. **Make the short name work.** `getent hosts db` must print `203.0.113.20`.

3. **Override one name locally.** Add a line to `/etc/hosts` so that `getent hosts www.lab.example` prints `198.51.100.80`. The DNS server must keep answering `203.0.113.10` for the same name (`dig +short @10.55.0.53 www.lab.example`).

The grader reads the drop-in files, the live `resolvectl status`, and `getent hosts` for both names.
