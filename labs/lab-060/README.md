# lab-060: Static Routing Across Multiple Interfaces

Two QEMU VMs for the LFCS course, joined on a real `backend-net` segment (10.10.20.0/24) via `runtime.networks` — `target` (10.10.20.5, the host you configure) and `gateway` (10.10.20.1, fronts the partner subnet `10.10.30.0/24` via its own `dummy0`). Adding and persisting a static route to a remote subnet, verified end to end by actually pinging through it.

## Run

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-060
```
