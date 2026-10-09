# Read A dig Answer

Astronaut, before you can judge a directory answer, you need to know who gave it and how to read it. This part follows a name lookup through the Domain Name System (DNS), shows the shape of a `dig` command, and walks through every part of its answer.

## How a name is looked up

DNS is the galaxy-wide directory of call signs. It turns a name like `www.lab.example` into the data a machine needs: usually an IP address, but also mail routing, text records and more. Several kinds of servers share the work, and `dig` lets you talk to any of them.

### The resolution path

- A **recursive resolver** is the directory clerk your machine asks. Its address is the `nameserver` line in `/etc/resolv.conf`.
- The clerk walks from the DNS root down to the **authoritative server**: the directory office that actually holds the page for that name.
- That page is the name's **zone**: one page of the directory, with one line (a **record**) per fact.
- The clerk returns the answer and keeps a copy for the record's **TTL** (time to live, in seconds).

```mermaid
flowchart LR
    C["your machine"] -->|"query"| R["recursive resolver"]
    R -->|"walks from the root"| A["authoritative server"]
    A -->|"record + TTL"| R
    R -->|"answer, cached"| C
```

The diagram shows one lookup: your machine asks the resolver, the resolver finds the authoritative server for the zone, and the answer comes back with a TTL that tells the resolver how long it may keep the copy.

### What `dig` does

`dig` (domain information groper) queries DNS directly and shows exactly what came back. An application only gets a short, cooked answer; `dig` shows the full response, with its status, its flags and every section.

## The shape of a `dig` command

Every `dig` command has the same shape. Three optional pieces decide which office you ask, what you ask for, and how much of the answer you see.

### The pattern

```text
dig [@server] [name] [type] [+options]
```

- With no `type`, `dig` asks for an `A` record (an IPv4 address).
- With no `@server`, it uses the resolver from `/etc/resolv.conf`.
- `+options` (always with a leading `+`) switch output sections on and off.

### What `dig` does not read

`dig` talks to DNS and nothing else. It does **not** read `/etc/hosts`, the ship's pocket address book. It also does **not** go through the Name Service Switch (NSS), the list in `nsswitch.conf` that tells the clerk which book to check first. So the `dig` answer can differ from what `ping`, `curl` or `getent hosts` return on the same machine: those use NSS, which usually checks `/etc/hosts` first. When a name resolves for `dig` but not for an application (or the other way round), that gap is the first thing to check.

`nslookup` and `host` query the same data with less detail. `resolvectl query` shows what `systemd-resolved` in particular would do.

## Anatomy of a `dig` answer

The default output has four parts: a header, the sections (QUESTION, ANSWER, and sometimes AUTHORITY and ADDITIONAL), and a footer with details about the query. Two header lines matter most.

### `status` and `flags`

- `status:` is the result. `NOERROR` means the server answered without an error. It does *not* promise that there are any records.
- `flags:` includes `aa` (authoritative answer) when the answer came from a server that owns the zone.

### Read a full response end to end

<!-- astrona:playground:renew -->

Ask for the `A` record of `www.lab.example`:

```sh
dig www.lab.example A
```

Expect something like:

```text
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 42137
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; QUESTION SECTION:
;www.lab.example.		IN	A

;; ANSWER SECTION:
www.lab.example.	3600	IN	A	203.0.113.10

;; Query time: 1 msec
;; SERVER: 127.0.0.1#53(127.0.0.1) (UDP)
```

`status: NOERROR` and one record in `ANSWER`. The `aa` flag says this server is authoritative for `lab.example`. The `3600` before `IN A` is the TTL in seconds. `SERVER: 127.0.0.1#53` confirms which server replied.

## Trimming the output

The full output is right for finding a fault; for a quick check it is noise. Two options cut it down.

### Two ways to trim

- `+short` prints only the record data, nothing else.
- `+noall +answer` switches off every section, then switches the ANSWER section back on. You keep the name, TTL, type and data, and drop the header and footer.

`MX` records (mail exchanger, the mail station for a domain) are a good example, because they carry two fields: a preference number (lower is tried first) and a mail host.

### The same query, three widths

Ask for the mail record three times, each time with less output:

```sh
dig lab.example MX
dig +noall +answer lab.example MX
dig +short lab.example MX
```

Expect the last two to be shorter and shorter:

```text
lab.example.		3600	IN	MX	10 mail.lab.example.
10 mail.lab.example.
```

`+short` gives you just `10 mail.lab.example.`: the preference and the host. That is handy in scripts, but it also drops the `status:` line. So a name that does not exist and a name with no records of that type both come back as empty output. When it matters, read the full response.

## Common pitfalls

> [!WARNING]
> - **`dig` ignores `/etc/hosts`.** It queries DNS directly. A name in `/etc/hosts` but not in DNS resolves for `ping` and fails for `dig`. That is expected, not a bug.
> - **`+short` hides the status.** `NXDOMAIN` and "no records of this type" both print nothing. For anything conditional, read the full response and check `status:`.
> - **`dig` exits 0 even for `NXDOMAIN`.** An exit code of zero means "got a response", not "the name exists". Scripts must read the output or `status:`, not just `$?`.
> - **Reading `NOERROR` as "found".** `NOERROR` only means no error; check that the ANSWER section is not empty.
