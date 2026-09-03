# Solution

## Step 1: Query the name using the system's default resolver

```bash
dig data-001.internal.example.com
```

Check `man dig` and read the output top to bottom once without `+short` — the full, un-abbreviated response is worth reading in full at least once so the section layout is familiar before relying on `+short` for everything else. The key sections:

- **QUESTION** — echoes back exactly what was asked (name, class `IN`, type `A` by default)
- **ANSWER** — the actual resource record(s) returned, each with its own TTL (seconds remaining before a resolver should re-query), class, type, and value
- **AUTHORITY** — nameservers considered authoritative for the zone, populated especially on referrals or when there's no direct answer
- **ADDITIONAL** — supplementary records, often the resolved IPs for anything named in AUTHORITY, saving an extra round trip

The `;; SERVER:` line near the bottom of the output shows exactly which resolver actually answered this query — worth checking any time the result looks unexpected, since it confirms whether the system default resolver (from `/etc/resolv.conf`) was used.

## Step 2: Get a bare, scriptable answer

```bash
dig +short data-001.internal.example.com
```

Check `man dig` for `+short` — it strips all the protocol framing and prints only the answer value(s), one per line, nothing else. This is the right form for piping into a script or a quick sanity check, but the full form from Step 1 is what you want when actually diagnosing a discrepancy, since `+short` throws away the TTL, the answering server, and the section structure that tells you *why* an answer looks the way it does.

## Step 3: Query a specific, known-good server directly — bypassing the system resolver entirely

```bash
dig @8.8.8.8 data-001.internal.example.com
```

Check `man dig` — the `@server` syntax (documented right in the SYNOPSIS) sends the query directly to that IP/hostname, completely ignoring whatever is configured in `/etc/resolv.conf`. This is the single most useful move for isolating a DNS problem: if this returns something different from Step 1's system-resolver query, the problem is local to `terminal`'s resolver configuration or cache, not the record itself. For an internal-only name like this scenario's, querying the organization's actual authoritative/internal DNS server directly (rather than a public resolver like `8.8.8.8`, which won't know an internal-only zone at all) is the realistic move — the public-resolver example above is shown for a public-name variant of the same technique.

```bash
DNS="$(getent hosts astrona-ats-003-lab-040-dns | awk '{print $1}')"
dig @"$DNS" data-001.internal.example.com
```

Comparing this against Step 1's result is the actual diagnostic step the scenario calls for — a match means the record and both resolvers agree (problem is elsewhere, e.g. the application, not DNS at all); a mismatch means `terminal`'s own resolver is the layer at fault. In this lab that's a genuinely independent check: Step 1 went through `terminal`'s configured resolver (`/etc/resolv.conf`), while this step talks directly to the authoritative server on a separate VM, bypassing local resolver config entirely.

## Step 4: Check MX and NS records for the domain

```bash
dig internal.example.com MX
dig internal.example.com NS
```

The record type is simply appended after the name (`dig NAME TYPE`) — `dig` defaults to `A` when no type is given, as seen in every prior step. `MX` answers "which mail server(s) handle email for this domain, and in what priority order" (a lower preference number means higher priority); `NS` answers "which nameservers are authoritative for this zone" — two different, non-interchangeable questions that happen to share the same query syntax.

## Step 5: Reverse-lookup the IP the record is supposed to point to

```bash
dig -x 192.168.10.80
```

Check `man dig` for `-x` — it's a convenience flag that automatically builds the correct `in-addr.arpa` (or `ip6.arpa` for IPv6) PTR query for the given address and swaps the octet order for you, so there's no need to hand-construct `80.10.168.192.in-addr.arpa` manually. A working forward record with no matching reverse (PTR) record is a common, legitimate asymmetry — not every environment maintains reverse zones — but confirming it either way is often part of a full DNS health check, especially for mail-related troubleshooting where missing PTR records commonly cause deliverability problems.

## Step 6: Trace the full delegation path if the record appears to be missing entirely

```bash
dig +trace data-001.internal.example.com
```

Check `man dig` for `+trace` — instead of asking one resolver for a final answer, this makes `dig` start at a root server and walk the delegation chain itself: root → TLD (or, for an internal zone, wherever the trace bottoms out) → the zone's own authoritative servers, printing the referral at each hop. This is the tool for the specific case where a plain query just returns NXDOMAIN or times out with no further explanation — `+trace` shows exactly which hop in the chain stopped producing a useful referral, which is far more actionable than a bare "not found." For a genuinely internal-only zone not delegated from the public root at all, `+trace` will visibly demonstrate that the chain never reaches an authoritative answer through the public hierarchy — itself useful confirmation that the name only resolves via an internal resolver/zone, not a diagnosis dead-end.

## Verification

```bash
dig +short data-001.internal.example.com
# 192.168.10.80

dig @"$DNS" +short data-001.internal.example.com
# 192.168.10.80
# (matches system resolver's answer -> record + both resolvers agree)

dig -x 192.168.10.80 +short
# data-001.internal.example.com.

dig internal.example.com NS +short
# ns1.internal.example.com.

dig internal.example.com MX +short
# 10 mail.internal.example.com.
```

Matching output between the system-resolver query and the direct-server query confirms the record itself is correct and consistent — any remaining "it doesn't resolve" complaint at that point points at the application or a client-side cache, not DNS.

## Command Summary

```bash
dig data-001.internal.example.com
dig +short data-001.internal.example.com
DNS="$(getent hosts astrona-ats-003-lab-040-dns | awk '{print $1}')"
dig @"$DNS" data-001.internal.example.com
dig internal.example.com MX
dig internal.example.com NS
dig -x 192.168.10.80
dig +trace data-001.internal.example.com
```
