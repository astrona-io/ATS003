# Overview: PLAYGROUND — Discovering Your Public IP Address (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server host. Reach it with
  `astrona ssh public-ip-playground`.
- Two private addresses, in two different RFC 1918 ranges:
  - the **management interface** — a private address in `10.0.0.0/8`, and it
    carries the host's **default route**;
  - an **extra NIC** — `172.16.20.50/24`, in `172.16.0.0/12`, added by
    `bootstrap/prepare.sh`.
- Tools: `curl`, `dig` (from `dnsutils`), `ip` (from `iproute2`).

## What you can always see (local)

- **The private addresses:** `ip addr show`, or the compact
  `ip -brief addr show`. Match each one against the RFC 1918 ranges:
  `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
- **The default route:** `ip route show`. The `default via <addr>` line points
  at a gateway that is itself a **private** address — not the public egress
  address. That is the whole reason a separate discovery step is needed.
- **Which interface leaves for the Internet:** `ip route get 1.1.1.1` reports
  the interface and gateway Linux would use, without sending anything.
- **Your IPv6 addresses, if any:** `ip -6 addr show`.

## What needs Internet egress

The module's discovery commands only return an answer when this environment can
reach the Internet:

```sh
curl -s https://ifconfig.me
curl -s https://icanhazip.com
dig +short TXT o-o.myaddr.l.google.com @ns1.google.com
```

- **If egress is available:** each returns the public address that service or
  DNS server observes for your outgoing connection — typically the address of a
  NAT gateway or router in front of this VM, not an address configured on the
  VM itself. The HTTP and DNS answers can differ if they leave by different
  paths.
- **If egress is blocked** (isolated sandbox): the `curl` commands hang until
  they time out (add `--max-time 5`), and the `dig` query returns nothing.
  Running them anyway is still worthwhile — a timeout here versus an answer on
  your laptop is a concrete demonstration that the public address lives
  *outside* this machine.

Force a protocol with `curl -4` / `curl -6` to compare the IPv4 and IPv6
egress addresses (again, only with connectivity).

## What this sandbox cannot show

- **Inbound reachability.** A discovered public address never proves the
  Internet can reach back in. Firewalls, missing port-forwards, and
  carrier-grade NAT all sit in the way. There is nothing to test that against
  here.
- **The NAT translation itself.** It happens on a router outside this VM, so it
  is not visible in any command run on the VM.

## When you're done

```sh
astrona destroy public-ip-playground
```

(`astrona destroy` takes the environment name, not the config path.)
