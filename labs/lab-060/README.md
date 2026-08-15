# lab-060: Static Routing Across Multiple Interfaces

Two QEMU VMs for the LFCS course — `target` (the host you configure) and `gateway` (fronts the partner subnet `10.10.30.0/24`) — adding and persisting a static route to a remote subnet, verified end to end by actually pinging through it. The gateway is reachable as `astrona-ats-003-lab-060-gateway`.

## Run

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-060
```
