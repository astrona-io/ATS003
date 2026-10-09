# Solution Walkthrough

The DNS server is already built on the `dns` machine. DNS, the Domain Name System, is the directory that turns names into addresses, and `dig` is the probe that asks one directory office one exact question. Your work is on `client`: point its resolver at that server, then run five `dig` lookups to confirm the zone. Open a shell with `astrona ssh client`.

| `dig` form | What it uses |
| --- | --- |
| `dig name` | the resolver in `/etc/resolv.conf` |
| `dig @1.2.3.4 name` | that server directly, ignoring `/etc/resolv.conf` |
| `dig -x 1.2.3.4` | a reverse (PTR) lookup |
| `+short` | print just the answer |

## The feedback loop

Grading runs from the **host terminal**, the shell where you typed `astrona run`:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-040/module-03/labs/lab-01
```

Six checks (`dns-server-ready` runs on the other machine and already passes):

```text
PASS  dns-server-ready
FAIL  system-resolver-a-record
FAIL  direct-server-a-record
FAIL  ns-record
FAIL  mx-record
FAIL  ptr-record
```

The lab's setup script already tries to point the client's resolver at `dns` when the lab starts, so on your first run some of these checks may already pass. Work through the steps anyway: the exam expects you to know how to do it yourself. Run the check after each step.

---

## Step 1: Find the `dns` server's address

On `client`:

```bash
cat /etc/resolv.conf
```

If it already has a `nameserver` line with a real address (not `127.0.0.53`), note that address: that is the `dns` machine.

If not, ask the client's own name lookup for the `dns` machine's lab name. This is the same lookup the grader uses:

```bash
getent hosts astrona-ats-003-lab-043-dns
```

The first column of the line it prints is the address. You can also read the address of the `dns` machine from the **host terminal**:

```bash
astrona list
```

Call that address `<dns-ip>` below.

---

## Step 2: Point the resolver at `dns`

On `client`, remove the old `/etc/resolv.conf` first, because `systemd-resolved` may own it:

```bash
sudo rm -f /etc/resolv.conf
```

Save this as `/etc/resolv.conf` (for example with `sudo nano /etc/resolv.conf`), with the real address in place of `<dns-ip>`:

```text
nameserver <dns-ip>
search internal.example.com
```

The resolver reads the file on every lookup, so there is nothing to restart. Then check the result:

```bash
dig +short data-001.internal.example.com A
```

It should print `192.168.10.80`.

**Run the check.** `system-resolver-a-record` now passes.

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

**Run the check.** `direct-server-a-record`, `ns-record`, `mx-record` and `ptr-record` now pass. All six are green.

---

## Step 4: Submit

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-040/module-03/labs/lab-01
```

---

## If a check stays red

- **`system-resolver-a-record` fails, answer empty.** `/etc/resolv.conf` is not pointing at the `dns` machine, or `systemd-resolved` wrote over it again. Remove the file again and save it as a plain file. If it keeps changing back, run `sudo systemctl stop systemd-resolved` first.
- **`direct-server-a-record` fails but the system one passes.** The grader looks up `astrona-ats-003-lab-043-dns` to find the server. Check that `getent hosts astrona-ats-003-lab-043-dns` prints an address, and that `ping <dns-ip>` gets replies.
- **`ns-record`, `mx-record` or `ptr-record` does not match.** Compare character for character, including the trailing `.`. Query the server directly with `@<dns-ip>` to rule out an old cached answer.
