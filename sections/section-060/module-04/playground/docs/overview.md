# Overview: PLAYGROUND — Raw Packet Capturing (tcpdump) (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh tcpdump-capture-playground`.
- `tcpdump`, `curl`, `python3`, `socat`, `ping`. Password-less `sudo`
  (`tcpdump` needs root to capture).
- **Steady traffic on the loopback interface (`lo`)**, generated every ~2
  seconds by `lab-traffic.service`:
  - an HTTP `GET http://127.0.0.1:8080/` (server: `lab-http.service`),
  - an ICMP echo to `127.0.0.1`,
  - a UDP datagram to `127.0.0.1:9999` (a closed port, so an ICMP
    port-unreachable comes back).
- A **sample capture** at `/usr/local/share/lab-sample.pcap` — so `tcpdump -r`
  has a file to read from the first minute.

Everything is on `lo`; there is no external network. `sudo systemctl stop
lab-traffic` silences the loop if you want a quiet interface.

## Things to try

- **Live capture.** `sudo tcpdump -i lo -n -c 10` — `-n` skips name lookups,
  `-c 10` stops after 10 packets. Without `-c` it runs until Ctrl-C.
- **Protocol filters.** `sudo tcpdump -i lo -n icmp`, `... tcp`, `... udp`,
  `... 'tcp port 8080'`, `... 'host 127.0.0.1 and not tcp'`.
- **See the payload.** `sudo tcpdump -i lo -n -A 'tcp port 8080'` — `-A` prints
  ASCII, so you can read the `GET /?t=... HTTP/1.1` request line and the
  `HTTP/1.0 200 OK` response. `-X` adds a hex + ASCII dump; `-XX` includes the
  link header.
- **Verbosity.** `-v`, `-vv`, `-vvv` add IP TTL, flags, options, and checksums.
- **Write and read a file.** `sudo tcpdump -i lo -n -c 20 -w /tmp/cap.pcap`,
  then `tcpdump -n -r /tmp/cap.pcap` (reading a file needs no root). Open the
  same file in Wireshark elsewhere.
- **Read the sample.** `tcpdump -n -r /usr/local/share/lab-sample.pcap | head`.
- **Timestamps.** `-tttt` for a full date-time per line; `-ttt` for delta from
  the previous packet.
- **Snap length.** `-s 96` captures only the first 96 bytes of each packet
  (headers, not full payload) — smaller files. Modern tcpdump defaults to the
  whole packet.
- **List interfaces.** `sudo tcpdump -D` (or `--list-interfaces`).
- **The "don't drown in your own session" habit.** On a box you are SSH'd into,
  `sudo tcpdump -i eth0 -n 'not port 22'` keeps your own SSH packets out of the
  capture. (Here you capture on `lo`, so SSH is already excluded.)
- **BPF building blocks.** `host` / `net` / `port` / `portrange`, `src` / `dst`,
  `tcp` / `udp` / `icmp` / `arp`, joined with `and` / `or` / `not`, e.g.
  `'dst port 8080 or icmp'`.

## What this sandbox does not set up

- **A real network path.** All traffic is loopback; there is no gateway, DNS,
  or remote host to capture between.
- **Wireshark.** Copy a `.pcap` off the VM to open it in a GUI.
- **Anything to grade.**

## When you're done

```sh
astrona destroy tcpdump-capture-playground
```

(`astrona destroy` takes the environment name, not the config path.)
