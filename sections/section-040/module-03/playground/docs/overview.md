# Overview: PLAYGROUND — DNS Verification with dig (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh dns-dig-playground`.
- `dig`, `nslookup`, `host` (from `bind9-dnsutils`).
- A **local authoritative BIND server** (`named`) answering on `127.0.0.1` for a
  made-up zone, `lab.example`, and its reverse zone `113.0.203.in-addr.arpa`.
  The machine's own resolver is pointed at `127.0.0.1`, so `dig lab.example`
  works with or without an explicit `@127.0.0.1`.
- There is **no internet DNS** here. `dig google.com` will fail — query the
  local zone instead.

### The zone (`lab.example`)

| Name | Type | Value |
| --- | --- | --- |
| `lab.example` | SOA / NS / MX / A / TXT | `ns1`, `mail` (pri 10), `203.0.113.10`, SPF |
| `www.lab.example` | A / AAAA | `203.0.113.10` / `2001:db8:113::10` |
| `mail.lab.example` | A | `203.0.113.20` |
| `app1` / `app2` | A | `203.0.113.31` / `203.0.113.32` |
| `web.lab.example` | CNAME | → `www.lab.example` |
| `short.lab.example` | A (TTL 30) | `203.0.113.99` — low TTL, watch it count down |
| `_dmarc.lab.example` | TXT | `v=DMARC1; p=none` |
| `10/20/31/32.113.0.203.in-addr.arpa` | PTR | back to the names above |

Zone transfer (`AXFR`) is **allowed from localhost for `lab.example`** and
**denied for the reverse zone** — so you can see both outcomes.

## Things to try

- **Record types.** `dig www.lab.example A`, `dig lab.example MX`,
  `dig lab.example NS`, `dig lab.example SOA`, `dig lab.example TXT`,
  `dig www.lab.example AAAA`, `dig web.lab.example` (watch the CNAME chain).
- **Target a server explicitly.** `dig @127.0.0.1 app1.lab.example` — the
  `@server` form ignores `/etc/resolv.conf`.
- **Trim the output.** `dig +short www.lab.example`,
  `dig +noall +answer lab.example MX`.
- **Reverse lookup.** `dig -x 203.0.113.20` — expect `mail.lab.example.`
- **TTL countdown.** `dig +noall +answer short.lab.example`, wait 10 seconds,
  run it again — the TTL column drops (the local server is authoritative, so it
  serves the fixed value; against a caching resolver it would count down).
- **Read the flags and status.** Full `dig lab.example` output — the `status:`
  (`NOERROR`, `NXDOMAIN`, `REFUSED`), the `flags:` (`aa` = authoritative
  answer), the `QUESTION` / `ANSWER` / `AUTHORITY` sections.
- **A name that does not exist.** `dig nope.lab.example` — `status: NXDOMAIN`.
- **Zone transfer.** `dig @127.0.0.1 lab.example AXFR` dumps the whole zone;
  `dig @127.0.0.1 113.0.203.in-addr.arpa AXFR` returns `; Transfer failed.`
- **`+trace`** starts from the root and will stall here (no internet root) —
  useful to see how far it gets.

## What this sandbox does not set up

- **Recursive resolution or internet DNS.** The server is authoritative only,
  for `lab.example`. Public names do not resolve.
- **DNSSEC.** `dnssec-validation` is off and the zone is unsigned.
- **A second host.** `@server` is exercised with `127.0.0.1`.
- **Anything to grade.**

## When you're done

```sh
astrona destroy dns-dig-playground
```

(`astrona destroy` takes the environment name, not the config path.)
