# Question

Solve this question on: `terminal`

## Scenario

`firewalld` is installed, running, enabled at boot, and the primary
interface is already bound to the `public` zone (which is also the default
zone). Your job is to open two things in that zone — and to make the change
both **live now** and **saved for after a reload/reboot**.

## Tasks

In the `public` zone:

1. **Allow the `https` service** — it must appear in both the runtime
   service list and the permanent service list.

2. **Allow port `8443/tcp`** — it must appear in both the runtime port list
   and the permanent port list.
