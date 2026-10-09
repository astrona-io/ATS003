# DNS Verification with dig

Astronaut, every ship in the galaxy has a call sign, but nobody remembers call signs. Ships look them up by name in the galaxy-wide directory: the **Domain Name System (DNS)**. When a name "does not resolve", a mail record looks wrong, or you need to know exactly what one directory office is handing out, you send a probe that asks one office one exact question. That probe is `dig`.

This module teaches you to send `dig` at the right office, ask the right question, and read every line of the answer.

## Learning objectives

After this module you can:

- Explain the DNS resolution path (recursive resolver, authoritative server, zone) and say where `dig` sends its query.
- Read a full `dig` answer: the `status`, the `flags` (including `aa`), and the QUESTION, ANSWER and AUTHORITY sections.
- Query any record type (`A`, `AAAA`, `MX`, `CNAME`, `TXT`, `NS`, `SOA`), and a reverse record with `dig -x`.
- Send a query to a specific server with `@server`, and explain when that matters.
- Trim output with `+short` and `+noall +answer`, and say what `+short` hides.
- Tell `NXDOMAIN`, `NODATA`, `SERVFAIL` and `REFUSED` apart in a `dig` result.

## Before you start

Every mission starts with a pre-flight check. Make sure you have the basics this module expects, and know what is waiting in your playground.

### What you should already know

- How to open a shell and run a command.
- What a domain name (`www.lab.example`) and an IP address (`203.0.113.10`) look like.
- That a Linux machine can also look names up in its own pocket address book, `/etc/hosts`, before it asks DNS. `dig` skips that book on purpose and talks straight to a DNS server.

DNS record types, zones, the time to live (TTL), and authoritative versus recursive servers are explained in the parts as they come up.

### What is in your playground

Your playground is one training ship with `dig`, `nslookup` and `host` installed, and a **local authoritative BIND server** (Berkeley Internet Name Domain, the program `named`) answering on `127.0.0.1`. It holds a made-up zone, `lab.example`, and its reverse zone `113.0.203.in-addr.arpa`. The machine's own resolver points at that server, so `dig lab.example` works with or without an explicit `@127.0.0.1`. Open a shell on it with `astrona ssh dns-dig-playground`.

There is **no internet DNS** here: `dig google.com` will fail, so query `lab.example` instead. The zone holds these records:

| Name | Type | Value |
| --- | --- | --- |
| `lab.example` | SOA / NS / MX / A / TXT | `ns1`, `mail` (pri 10), `203.0.113.10`, SPF |
| `www.lab.example` | A / AAAA | `203.0.113.10` / `2001:db8:113::10` |
| `mail.lab.example` | A | `203.0.113.20` |
| `app1` / `app2` | A | `203.0.113.31` / `203.0.113.32` |
| `web.lab.example` | CNAME | → `www.lab.example` |
| `short.lab.example` | A (TTL 30) | `203.0.113.99`, a low TTL you can watch count down |
| `_dmarc.lab.example` | TXT | `v=DMARC1; p=none` |
| `10/20/31/32.113.0.203.in-addr.arpa` | PTR | back to the names above |

A zone transfer (`AXFR`) is allowed from the machine itself for `lab.example`, and denied for the reverse zone, so you can see both outcomes.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Read A dig Answer](./course-01-read-a-dig-answer.md): the resolution path, the shape of a `dig` command, and every part of its answer.
2. [Ask The Right Server The Right Question](./course-02-ask-the-right-server-the-right-question.md): `@server`, reverse lookups, and the difference between `NXDOMAIN` and `NODATA`.
3. [Aliases And Zone Transfers](./course-03-aliases-and-zone-transfers.md): `CNAME` records and `AXFR`.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, and cleanup.

## Why this matters

`dig` is how you prove what DNS really says. It shows whether a record exists, which server gave the answer, and whether that server owns the zone. That lets you tell "the record is wrong" apart from "the machine asks the wrong server" apart from "a cache is old". The exam expects you to point a machine at a DNS server and check its records with `dig` quickly and exactly.
