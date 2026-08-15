# lab-090: NTP Server Mode and Stratum

Two QEMU VMs for the LFCS course — `server` (data-001's role) and `client` (app-srv1's role) — configuring chronyd to serve NTP to an internal subnet and verifying the resulting stratum hierarchy end to end. The client reaches the server as `astrona-ats-003-lab-090-server`.

## Run

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-090
```
