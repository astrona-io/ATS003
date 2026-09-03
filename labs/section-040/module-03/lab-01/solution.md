# Solution Walkthrough

The DNS server is already built on the `dns` VM. Your work is on `client`:
point its resolver at that server, then run five `dig` lookups to confirm
the zone. Open a shell with `astrona ssh client`.

| `dig` form | What it uses |
| --- | --- |
| `dig name` | the resolver in `/etc/resolv.conf` |
| `dig @1.2.3.4 name` | that server directly, ignoring `/etc/resolv.conf` |
| `dig -x 1.2.3.4` | a reverse (PTR) lookup |
| `+short` | print just the answer |

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`:

```bash
astrona test -c labs/section-040/module-03/lab-01
```

Six checks (`dns-server-ready` runs on the other VM and already passes):

```text
PASS  dns-server-ready
FAIL  system-resolver-a-record
FAIL  direct-server-a-record
FAIL  ns-record
FAIL  mx-record
FAIL  ptr-record
```

Run it after each step.

---

## Step 1: Find the `dns` server's address

On `client`:

```bash
cat /etc/resolv.conf
```

If it already has a `nameserver` line with a real address (not
`127.0.0.53`), note that address — that is the `dns` VM. If not, get it from
the **host terminal**:

```bash
astrona list
```

and read the IP of the `dns` VM. Call it `<dns-ip>` below.

---

## Step 2: Point the resolver at `dns`

On `client`, replace `/etc/resolv.conf` with a static file pointing at the
server (`systemd-resolved` may own the old one, so remove it first):

```bash
sudo rm -f /etc/resolv.conf
sudo nano /etc/resolv.conf
```

Put exactly this in it, with the real address:

```text
nameserver <dns-ip>
search internal.example.com
```

Save and exit. Test:

```bash
dig +short data-001.internal.example.com A
```

It should print `192.168.10.80`.

**Run the check** — `system-resolver-a-record` now passes.

---

## Step 3: Verify the rest of the records

Run each lookup and confirm the answer:

```bash
dig @<dns-ip> +short data-001.internal.example.com A
# -> 192.168.10.80   (direct query, bypassing resolv.conf)

dig +short internal.example.com NS
# -> ns1.internal.example.com.

dig +short internal.example.com MX
# -> 10 mail.internal.example.com.

dig -x 192.168.10.80 +short
# -> data-001.internal.example.com.
```

Every answer must match exactly, trailing dot included.

**Run the check** — `direct-server-a-record`, `ns-record`, `mx-record`, and
`ptr-record` now pass. All six green.

---

## Step 4: Submit

```bash
astrona submit -c labs/section-040/module-03/lab-01
```

---

## If a check stays red

- **`system-resolver-a-record` fails, answer empty.** `/etc/resolv.conf` is
  not pointing at the `dns` VM, or `systemd-resolved` overwrote it again.
  Re-remove the file, recreate it static, and if it keeps reverting run
  `sudo systemctl stop systemd-resolved` first.
- **`direct-server-a-record` fails but the system one passes.** Wrong
  `<dns-ip>`, or the `dns` VM is unreachable — check `ping <dns-ip>`.
- **`ns-record` / `mx-record` / `ptr-record` mismatch.** Compare
  character-for-character, including the trailing `.`. Query the server
  directly with `@<dns-ip>` to rule out a stale cache.
