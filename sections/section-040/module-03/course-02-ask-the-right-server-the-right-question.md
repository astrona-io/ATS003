# Ask The Right Server The Right Question

Astronaut, a probe is only useful if it goes to the right directory office and asks the right question. In this part you choose which DNS server answers, look up a name from its address, and learn the two kinds of "no answer" that look the same at first glance.

## Choosing which server to ask

Without `@server`, `dig` asks the directory clerk named in `/etc/resolv.conf`: the address on its `nameserver` line. `@server` sends the query to a server you name instead. DNS is the Domain Name System, the galaxy-wide directory of call signs.

### When to name the server

Use `@server` to:

- ask an authoritative server directly, skipping any cached copy,
- compare what two servers return,
- test a resolver before you point the machine at it.

To see which server a plain `dig` uses, run `cat /etc/resolv.conf` and look at the `nameserver` line.

### Query the local server explicitly

<!-- astrona:playground:renew -->

Send the question straight to the playground's server:

```sh
dig @127.0.0.1 app1.lab.example
```

Expect an authoritative answer for `app1`:

```text
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, ...
app1.lab.example.	3600	IN	A	203.0.113.31
```

Here `@127.0.0.1` points at the same server the resolver would have used anyway, so the answer is the same. On a real network, comparing `dig @ns1.example …` with `dig @8.8.8.8 …` is how you tell "the authoritative data is wrong" apart from "a cache is old".

## Reverse lookups: address to name

The other direction, "given an address, which name claims it?", is stored as `PTR` (pointer) records in a special zone. For IPv4 that zone ends in `in-addr.arpa`. `dig -x <address>` builds that query name for you.

### Go from address back to name

Look up who claims `203.0.113.20`:

```sh
dig -x 203.0.113.20
```

Expect the pointer record:

```text
;; QUESTION SECTION:
;20.113.0.203.in-addr.arpa.	IN	PTR

;; ANSWER SECTION:
20.113.0.203.in-addr.arpa. 3600	IN	PTR	mail.lab.example.
```

`dig` turned the four numbers around and added `in-addr.arpa` to build the query. The answer, `mail.lab.example.`, is what the owner of that address block chose to publish. Forward and reverse records live in separate zones, so they can disagree.

## When there is no answer: `NXDOMAIN` versus `NODATA`

An empty ANSWER section has two very different causes, and the `status:` line tells them apart. Knowing which one you have tells you where to look next.

### The four statuses to know

- **`NXDOMAIN`**: the name does not exist at all.
- **`NOERROR` with `ANSWER: 0`** (called "NODATA"): the name exists, but has no record of the type you asked for.
- **`SERVFAIL`**: the resolver could not complete the lookup.
- **`REFUSED`**: the server will not answer this query from you.

### A missing name and a missing record type

`lab.example` has an `A` record at its top but no `AAAA` record. Ask for a name that does not exist, then for a record type that does not exist:

```sh
dig nope.lab.example
dig lab.example AAAA
```

Compare the `status:` lines:

```text
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: ...
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: ...
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1
```

The first query gives `NXDOMAIN`: `nope` is not in the zone. The second gives `NOERROR` but zero answers: `lab.example` exists, it just has no IPv6 address. `+short` would have shown nothing for both; the status is the difference.

## Common pitfalls

> [!WARNING]
> - **Asking the wrong server.** A recursive resolver can serve an old cached record; the authoritative server has the current data. Use `@` to compare when an answer looks wrong.
> - **Expecting forward and reverse to match.** `A` and `PTR` records live in separate zones, often run by different owners. One can be right while the other is missing or wrong.
> - **Trailing dot and search domains.** `dig host` with no dot may get a search domain from `/etc/resolv.conf` added. `dig host.` (with the trailing dot) forces the exact name.
> - **Forgetting the trailing dot in answers.** `dig +short` prints names with a final `.` (`mail.lab.example.`). When you compare answers, that dot is part of the name.

## Your mission: DNS Verification with dig Lab

You can now send `dig` to a chosen server, look up names from addresses, and read the status of any answer. Now prove it in a graded mission: make a client use an internal DNS server as its resolver, and check that server's address, name server, mail and reverse records with `dig`.

The mission runs on its own training ships, so first pause your playground. Nothing in it is lost:

```sh
astrona stop dns-dig-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-040/module-03/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-043
astrona start dns-dig-playground
```
