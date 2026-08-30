# DNS Verification with dig

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-040/module-03/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-040/module-03/playground
> astrona destroy dns-dig-playground
> ```

The **Domain Name System (DNS)** turns a name like `www.lab.example` into the data a machine needs — usually an IP address, but also mail routing, text records, and more. The lookup travels a hierarchy: a **recursive resolver** (the server in your `/etc/resolv.conf`) walks from the DNS root down to the **authoritative server** that actually holds the name's **zone**, and returns the answer. The resolver then caches it for the record's **TTL** (time to live, in seconds).

`dig` (domain information groper) queries DNS directly and shows exactly what came back — not the cooked one-line answer an application gets, but the full response with its status, flags, and every section. When a site "doesn't resolve", a mail record looks wrong, or you need to check what a specific server is handing out, `dig` is the instrument.

Its shape is:

```text
dig [@server] [name] [type] [+options]
```

With no `type` it asks for an `A` record; with no `@server` it uses the resolver from `/etc/resolv.conf`; `+options` (always with a leading `+`) switch output sections on and off.

## Learning objectives

After this module you can:

- Explain the DNS resolution path — recursive resolver, authoritative server, zone — and say where `dig` sends its query.
- Read a full `dig` answer: the `status`, the `flags` (including `aa`), and the QUESTION / ANSWER / AUTHORITY sections.
- Query any record type — `A`, `AAAA`, `MX`, `CNAME`, `TXT`, `NS`, `SOA` — and a reverse record with `dig -x`.
- Direct a query at a specific server with `@server`, and explain when that matters.
- Trim output with `+short` and `+noall +answer`, and say what `+short` hides.
- Tell `NXDOMAIN`, `NODATA`, `SERVFAIL`, and `REFUSED` apart in a `dig` result.

## Before you start

This module assumes you can open a shell and have seen a domain name and an IP address. DNS record types, zones, TTL, and authoritative-versus-recursive are defined as they come up. The local name-resolution module (`/etc/hosts` and NSS) is useful contrast — `dig` deliberately skips both and talks straight to a DNS server.

The playground is a single VM. Open a shell on it with `astrona ssh astro-dns-dig-playground`. It runs `dig` and a **local authoritative BIND server** for a made-up zone, `lab.example`, plus its reverse zone. The VM's own resolver points at that server, so `dig lab.example` works with or without an explicit `@127.0.0.1`. There is **no internet DNS** — `dig google.com` will fail; query `lab.example`. The zone holds `A` / `AAAA` / `MX` / `CNAME` / `TXT` / `NS` / `SOA` / `PTR` records and a low-TTL name, `short.lab.example`. Zone transfer is allowed from localhost for the forward zone and denied for the reverse one.

## Where this fits

`dig` talks to DNS and nothing else. It does **not** read `/etc/hosts` and does **not** go through the Name Service Switch, so its answer can differ from what `ping`, `curl`, or `getent hosts` return on the same machine — those use NSS, which usually checks `/etc/hosts` first. When a name resolves for `dig` but not for an application (or the reverse), that gap is the first thing to check.

`dig` is also how you verify the work of the NTP, mail, and web modules from the DNS side: an NTP `pool` name, an `MX` for a mail domain, the `A`/`AAAA` a web service is published under. `nslookup` and `host` query the same data with less detail; `resolvectl query` shows what `systemd-resolved` specifically would do.

## Anatomy of a `dig` answer

The default output has four parts: a header, the sections (QUESTION, ANSWER, and sometimes AUTHORITY / ADDITIONAL), and a footer of query metadata. The header line that matters most is `status:` — `NOERROR` means the server answered without error (it does *not* promise there are any records). The `flags:` line includes `aa` when the answer came from a server **authoritative** for the zone.

> [!TIP]
> **Try it — read a full response end to end**
>
> ```sh
> dig www.lab.example A
> ```
>
> Expect something like:
>
> ```text
> ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 42137
> ;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2
>
> ;; QUESTION SECTION:
> ;www.lab.example.		IN	A
>
> ;; ANSWER SECTION:
> www.lab.example.	3600	IN	A	203.0.113.10
>
> ;; Query time: 1 msec
> ;; SERVER: 127.0.0.1#53(127.0.0.1) (UDP)
> ```
>
> `status: NOERROR` and one record in `ANSWER`. The `aa` flag says this server is authoritative for `lab.example`. The `3600` before `IN A` is the TTL in seconds. `SERVER: 127.0.0.1#53` confirms which server replied.

## Trimming the output

Full output is right for diagnosis; for a quick check it is noise. Two options cut it down:

- `+short` — print only the record data, nothing else.
- `+noall +answer` — suppress every section, then turn the ANSWER section back on. You keep the name/TTL/type/data table but drop the header and footer.

`MX` records are a good example because they carry two fields — a preference number (lower is tried first) and a mail host.

> [!TIP]
> **Try it — the same query, three widths**
>
> ```sh
> dig lab.example MX
> dig +noall +answer lab.example MX
> dig +short lab.example MX
> ```
>
> Expect the last two to be progressively terser:
>
> ```text
> lab.example.		3600	IN	MX	10 mail.lab.example.
> 10 mail.lab.example.
> ```
>
> `+short` gives you just `10 mail.lab.example.` — the preference and the host. Handy in scripts, but note it also drops the `status:` line, so a name that does not exist and a name with no records of that type both come back as empty output. When it matters, read the full response.

## Choosing which server to ask

`@server` sends the query to a named server instead of the one in `/etc/resolv.conf`. Use it to ask an authoritative server directly (bypassing any cache), to compare what two servers return, or to test a resolver you are about to configure.

> [!TIP]
> **Try it — query the local server explicitly**
>
> ```sh
> dig @127.0.0.1 app1.lab.example
> ```
>
> Expect an authoritative answer for `app1`:
>
> ```text
> ;; flags: qr aa rd; QUERY: 1, ANSWER: 1, ...
> app1.lab.example.	3600	IN	A	203.0.113.31
> ```
>
> Here `@127.0.0.1` points at the same server the resolver would have used anyway, so the answer is identical — but on a real network, `dig @ns1.example …` versus `dig @8.8.8.8 …` is how you tell "the authoritative data is wrong" from "a cache is stale".

## CNAME: an alias to another name

A `CNAME` record makes one name an alias for another. A query for the alias comes back with the `CNAME` *and* then the records for the real name — `dig` follows the chain in one response.

> [!TIP]
> **Try it — follow an alias**
>
> ```sh
> dig web.lab.example
> ```
>
> Expect both the alias and the target it resolves to:
>
> ```text
> ;; ANSWER SECTION:
> web.lab.example.	3600	IN	CNAME	www.lab.example.
> www.lab.example.	3600	IN	A	203.0.113.10
> ```
>
> `web` is not an address — it is a pointer to `www`, and `www` is the `A` record. Applications that look up `web.lab.example` end up at `203.0.113.10`.

## Reverse lookups: address to name

The reverse direction — given an IP, what name claims it — is stored as `PTR` records in a special zone (`…in-addr.arpa` for IPv4). `dig -x <address>` builds that query name for you.

> [!TIP]
> **Try it — go from address back to name**
>
> ```sh
> dig -x 203.0.113.20
> ```
>
> Expect the pointer record:
>
> ```text
> ;; QUESTION SECTION:
> ;20.113.0.203.in-addr.arpa.	IN	PTR
>
> ;; ANSWER SECTION:
> 20.113.0.203.in-addr.arpa. 3600	IN	PTR	mail.lab.example.
> ```
>
> `dig` reversed the octets and appended `in-addr.arpa` to form the query. The answer, `mail.lab.example.`, is what the owner of that address block chose to publish — forward and reverse are separate zones and can disagree.

## When there is no answer: `NXDOMAIN` versus `NODATA`

An empty `ANSWER` section has two very different causes, and the `status:` line tells them apart:

- **`NXDOMAIN`** — the name does not exist at all.
- **`NOERROR` with `ANSWER: 0`** ("NODATA") — the name exists, but has no record of the type you asked for.

`SERVFAIL` (the resolver could not complete the lookup) and `REFUSED` (the server will not answer this query from you) are two more you will meet.

> [!TIP]
> **Try it — a missing name and a missing record type**
>
> `lab.example` has an `A` record at its apex but no `AAAA`:
>
> ```sh
> dig nope.lab.example
> dig lab.example AAAA
> ```
>
> Compare the `status:` lines:
>
> ```text
> ;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: ...
> ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: ...
> ;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1
> ```
>
> First query: `NXDOMAIN` — `nope` is not in the zone. Second: `NOERROR` but zero answers — `lab.example` exists, it just has no IPv6 address. `+short` would have shown nothing for both; the status is the difference.

## Zone transfer (`AXFR`)

A zone transfer asks a server for *every* record in a zone at once — how a secondary name server copies a zone from the primary. `dig @server <zone> AXFR` requests one. Servers normally restrict it to known secondaries, because an open transfer hands an attacker a complete map of the network.

> [!TIP]
> **Try it — an allowed transfer and a refused one**
>
> The forward zone allows transfers from localhost; the reverse zone does not:
>
> ```sh
> dig @127.0.0.1 lab.example AXFR
> dig @127.0.0.1 113.0.203.in-addr.arpa AXFR
> ```
>
> Expect the first to dump the whole zone (it starts and ends with the `SOA` record) and the second to fail:
>
> ```text
> lab.example.  3600  IN  SOA  ns1.lab.example. admin.lab.example. 2024010101 ...
> lab.example.  3600  IN  NS   ns1.lab.example.
> ... every record ...
> lab.example.  3600  IN  SOA  ns1.lab.example. admin.lab.example. 2024010101 ...
> ```
>
> ```text
> ; Transfer failed.
> ```
>
> Same server, same command, different zone — one permits the transfer, the other returns nothing. On a server you run, `AXFR` should be denied to everyone except your secondaries.

> [!WARNING]
> **Common pitfalls**
>
> - **`dig` ignores `/etc/hosts`.** It queries DNS directly. A name in `/etc/hosts` but not in DNS resolves for `ping` and fails for `dig` — that is expected, not a bug.
> - **`+short` hides the status.** `NXDOMAIN` and "no records of this type" both print nothing. For anything conditional, read the full response and check `status:`.
> - **`dig` exits 0 even for `NXDOMAIN`.** A zero exit code means "got a response", not "the name exists". Scripts must inspect the output or `status:`, not just `$?`.
> - **Asking the wrong server.** A recursive resolver can serve a stale cached record; the authoritative server has the current data. Use `@` to compare when an answer looks wrong.
> - **Expecting forward and reverse to match.** `A` and `PTR` live in separate zones, often run by different owners. One can be right while the other is missing or wrong.
> - **A `CNAME` at a zone apex.** `example.com. IN CNAME …` is invalid — the apex must hold `SOA` and `NS` records, which cannot coexist with a `CNAME`. Use an `A`/`AAAA` (or a provider's `ALIAS`/`ANAME`) there instead.
> - **Trailing dot and search domains.** `dig host` with no dot may get a search domain from `/etc/resolv.conf` appended. `dig host.` (trailing dot) forces the exact name.
