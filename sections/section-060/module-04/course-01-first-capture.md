# Your First Capture

Astronaut, in this part you clip the recorder onto an antenna for the first time. You learn what a capture really records, how to read one line of tcpdump output, and how to grab a handful of packets without drowning in them.

## What packet capture is

**Packet capture** means reading a copy of every frame as it passes a network interface. You see the actual bytes on the wire, not what an application reports.

### Why it is the tie-breaker

A capture shows which packets left, which came back, and what they contained. tcpdump shows layers 2 to 4 (link, network and transport) as they really are, so it settles things when higher-level tools disagree. Pair it with `ss` ("the process says it is listening: does a SYN even arrive?"), with the firewall (capture on *both* sides of a filter to see where a packet is dropped), and with `dig` ("which DNS (Domain Name System, the galaxy-wide directory of call signs) question did the resolver really send?").

Wireshark is the graphical analyser with deep protocol decoders, and `tshark` is its command-line version. `tcpdump` is the one already installed on the server at 3 in the morning.

### How tcpdump captures

**tcpdump** is the standard command-line capture tool. It uses the `libpcap` library and needs **root**. It opens a raw socket and, by default, puts the interface into *promiscuous mode*, so it sees frames not addressed to this host. It prints one line per packet, or writes the raw packets to a **`.pcap`** file for later analysis or for Wireshark.

Capturing can expose passwords, session tokens and personal data. Only capture on systems you are allowed to, and treat `.pcap` files as sensitive.

## Reading a tcpdump line

Every line follows the same order. Once you can read one, you can read them all.

### A line, decoded

```text
12:00:00.123456 IP 127.0.0.1.44321 > 127.0.0.1.8080: Flags [S], seq 12345, win 65495, length 0
     timestamp   L3  source:port    dest:port     TCP flags   seq no.   window   payload bytes
```

The TCP (Transmission Control Protocol, a channel where both sides confirm every signal) flags tell you what kind of packet it is:

- `Flags [S]` is a SYN, the start of a connection.
- `[S.]` is a SYN-ACK, the answer to it.
- `[P.]` is push plus ACK: data.
- `[F.]` is a FIN, a polite close.
- `[R]` is a reset, an abrupt refusal or close.

## Reading the command

A command is `tcpdump [options] [filter expression]`. The options fall into three groups.

### The option groups

| Group | Flags | Effect |
|---|---|---|
| **Capture control** | `-i <iface>` interface, `-c N` stop after N, `-w file` write raw, `-r file` read raw, `-s N` snap length | what and how much is captured |
| **Name resolution** | `-n` no host lookup, `-nn` also no port-to-service lookup | keep output fast and unambiguous |
| **Output detail** | `-v`/`-vv`/`-vvv`, `-A` ASCII payload, `-X` hex and ASCII, `-e` link-layer header, `-tttt` wall-clock time | shape each line without changing what is captured |

The **filter expression** is the last argument. tcpdump compiles it to BPF (Berkeley Packet Filter) code that runs in the kernel, so packets that do not match are dropped before tcpdump sees them.

A simple way to remember it: `-i` picks the antenna, `-n` keeps it readable, `-c` or `-w` limit the run, and the expression at the end narrows what you record.

## A first capture

`-c N` makes tcpdump stop after N packets instead of running until you press Ctrl-C. `-n` avoids DNS lookups that would otherwise show up in your own capture.

### Five packets off the loopback

<!-- astrona:playground:renew -->

Capture five packets on `lo`:

```sh
sudo tcpdump -i lo -n -c 5
```

Expect a mix of the seeded traffic:

```text
12:00:00.100 IP 127.0.0.1.44322 > 127.0.0.1.8080: Flags [S], seq 1, win 65495, length 0
12:00:00.100 IP 127.0.0.1.8080 > 127.0.0.1.44322: Flags [S.], seq 1, ack 2, win 65483, length 0
12:00:00.100 IP 127.0.0.1.44322 > 127.0.0.1.8080: Flags [.], ack 1, win 512, length 0
12:00:00.100 IP 127.0.0.1.44322 > 127.0.0.1.8080: Flags [P.], seq 1:88, ack 1, length 87: HTTP: GET /?t=... HTTP/1.1
12:00:01.200 IP 127.0.0.1 > 127.0.0.1: ICMP echo request, id 5, seq 1, length 64
```

The first three lines are a TCP handshake (`[S]`, `[S.]`, `[.]`). The fourth carries the HTTP (Hypertext Transfer Protocol, the language of web requests) request, and the fifth is the ICMP (Internet Control Message Protocol, the short status signals such as ping) ping. Timestamps, ports and sequence numbers change on every run.

## Common pitfalls

> [!WARNING]
> - **No `-n` or `-nn`.** tcpdump does reverse DNS and service-name lookups that slow the output and create their own traffic, which then shows up in the capture. Always use `-n` (or `-nn`) for diagnostics.
> - **Running as a normal user.** You get "You don't have permission to capture on that device." Capturing needs root or `CAP_NET_RAW`; *reading* a `.pcap` file does not.
> - **Forgetting `-c`.** Without it, tcpdump runs until you press Ctrl-C.
