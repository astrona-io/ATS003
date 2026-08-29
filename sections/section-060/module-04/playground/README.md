# Raw Packet Capturing (tcpdump) — Playground

- **ID:** PLAYGROUND
- **Slug:** tcpdump-capture-playground
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Single VM with a local HTTP server and a loop that keeps steady traffic (HTTP,
ICMP, and a UDP datagram that draws an ICMP unreachable) moving on the loopback
interface, plus a sample `.pcap`, so every `tcpdump` filter and output flag has
packets to show — offline, no external network.

A single sandbox environment that spins up, runs OS prep, and stays running so
you can explore the module's topic on a clean machine. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy tcpdump-capture-playground
```

`astrona destroy` takes the environment name (`metadata.name` =
`tcpdump-capture-playground`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Starts the HTTP server + traffic loop, saves a sample .pcap |
| `docs/overview.md` | The traffic on `lo` and `tcpdump` invocations to try |
