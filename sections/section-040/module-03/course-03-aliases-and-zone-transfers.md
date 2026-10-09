# Aliases And Zone Transfers

Astronaut, some directory lines do not hold an address at all: they point to another line. And sometimes a directory office hands over its whole page at once. This part shows both: the `CNAME` alias and the `AXFR` zone transfer.

## CNAME: an alias to another name

A `CNAME` (canonical name) record makes one name an alias for another. A query for the alias comes back with the `CNAME` *and* then the records for the real name: `dig` follows the chain in one response.

### Follow an alias

<!-- astrona:playground:renew -->

Look up the alias `web.lab.example`:

```sh
dig web.lab.example
```

Expect both the alias and the target it points to:

```text
;; ANSWER SECTION:
web.lab.example.	3600	IN	CNAME	www.lab.example.
www.lab.example.	3600	IN	A	203.0.113.10
```

`web` is not an address. It is a pointer to `www`, and `www` holds the `A` record. Applications that look up `web.lab.example` end up at `203.0.113.10`.

## Zone transfer (`AXFR`)

A zone transfer asks a server for *every* record in a zone at once. A secondary name server uses it to copy a zone from the primary. `dig @server <zone> AXFR` requests one.

### Why servers restrict it

Servers normally allow transfers only to their known secondary servers. An open transfer hands an attacker a complete map of the network: every name and every address in one reply.

### An allowed transfer and a refused one

In the playground, the forward zone allows transfers from the machine itself, and the reverse zone does not. Ask for both:

```sh
dig @127.0.0.1 lab.example AXFR
dig @127.0.0.1 113.0.203.in-addr.arpa AXFR
```

Expect the first to print the whole zone (it starts and ends with the `SOA` record, the start of authority line) and the second to fail:

```text
lab.example.  3600  IN  SOA  ns1.lab.example. admin.lab.example. 2024010101 ...
lab.example.  3600  IN  NS   ns1.lab.example.
... every record ...
lab.example.  3600  IN  SOA  ns1.lab.example. admin.lab.example. 2024010101 ...
```

```text
; Transfer failed.
```

Same server, same command, different zone: one permits the transfer, the other returns nothing. The `NS` line in the first answer names `ns1.lab.example.` as the name server, the directory keeper, for this zone. On a server you run, deny `AXFR` to everyone except your secondary servers.

## Common pitfalls

> [!WARNING]
> - **A `CNAME` at a zone's top.** `example.com. IN CNAME …` is invalid: the top of a zone must hold `SOA` and `NS` records, which cannot live next to a `CNAME`. Use an `A` or `AAAA` record there instead (or a provider's `ALIAS` or `ANAME` record).
> - **Leaving zone transfers open.** An `AXFR` anyone can run gives away every name in the zone. Allow it only for your secondary servers.
> - **Reading a `CNAME` as an address.** The alias only points to another name; the address comes from that name's `A` or `AAAA` record.
