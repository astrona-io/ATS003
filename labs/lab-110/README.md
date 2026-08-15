# lab-110: DNS Verification with dig

Two QEMU VMs for the LFCS course — `client` (terminal's role) and `dns` (the authoritative internal DNS server) — using `dig` to isolate whether a DNS problem lives in the record, the resolver, or delegation, across a real network hop between two genuinely independent machines. The server is reachable as `astrona-ats-003-lab-110-dns`.

## Run

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-110
```
