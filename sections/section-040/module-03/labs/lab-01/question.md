# Question

Solve this question on: `client`

## Scenario

Astronaut, this mission has two training ships. `dns` runs an internal authoritative BIND server (the DNS server program) for the zone `internal.example.com` and its reverse zone. DNS is the Domain Name System, the directory that turns names into addresses. You work on `client`. Its job is to use that server for name resolution, and to confirm with `dig` that the zone's records are correct.

## Tasks

On `client`:

1. **Point the system resolver at `dns`.** Set `/etc/resolv.conf` so that a plain `dig name` (no `@server`) queries the `dns` machine. After this, `dig +short data-001.internal.example.com` returns `192.168.10.80`.

2. **Verify every record below resolves as shown.** These are the exact lookups the checks run:

   | Query | Expected answer |
   | --- | --- |
   | `dig +short data-001.internal.example.com A` (system resolver) | `192.168.10.80` |
   | `dig @<dns-ip> +short data-001.internal.example.com A` (direct) | `192.168.10.80` |
   | `dig +short internal.example.com NS` | `ns1.internal.example.com.` |
   | `dig +short internal.example.com MX` | `10 mail.internal.example.com.` |
   | `dig -x 192.168.10.80 +short` | `data-001.internal.example.com.` |

   `<dns-ip>` is the address of the `dns` machine on the lab network. The check finds it by looking up the name `astrona-ats-003-lab-043-dns`.
