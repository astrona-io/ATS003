# Question

Solve this question on: `client`

## Scenario

Two machines. `dns` runs an internal authoritative BIND server for the zone
`internal.example.com` (and its reverse zone). You work on `client`. Its
job is to use that server for name resolution and confirm the zone's
records are correct with `dig`.

## Tasks

On `client`:

1. **Point the system resolver at `dns`.** Set `/etc/resolv.conf` so that a
   plain `dig name` (no `@server`) queries the `dns` VM. After this,
   `dig +short data-001.internal.example.com` returns `192.168.10.80`.

2. **Verify every record below resolves as shown** (these are the exact
   lookups the checks run):

   | Query | Expected answer |
   | --- | --- |
   | `dig +short data-001.internal.example.com A` (system resolver) | `192.168.10.80` |
   | `dig @<dns-ip> +short data-001.internal.example.com A` (direct) | `192.168.10.80` |
   | `dig +short internal.example.com NS` | `ns1.internal.example.com.` |
   | `dig +short internal.example.com MX` | `10 mail.internal.example.com.` |
   | `dig -x 192.168.10.80 +short` | `data-001.internal.example.com.` |
