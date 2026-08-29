# Raw Packet Capturing (tcpdump)

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-060/module-04/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-04/playground
> astrona destroy tcpdump-capture-playground
> ```

**Packet capture** is reading a copy of every frame as it passes a network
interface — the actual bytes on the wire, not what an application reports. When a
connection times out, gets refused, or behaves in a way the logs do not explain,
a capture shows the ground truth: which packets left, which came back, and what
they contained.

**tcpdump** is the standard command-line capture tool. It uses the `libpcap`
library, needs **root** (it opens a raw socket and, by default, puts the
interface into *promiscuous mode* so it sees frames not addressed to this host),
and prints one line per packet — or writes the raw packets to a **`.pcap`** file
for later analysis or for Wireshark.

A capture line, decoded:

```text
12:00:00.123456 IP 127.0.0.1.44321 > 127.0.0.1.8080: Flags [S], seq 12345, win 65495, length 0
     timestamp   L3  source:port    dest:port     TCP flags   seq no.   window   payload bytes
```

`Flags [S]` is a SYN (connection start); `[S.]` is SYN-ACK, `[P.]` push+ACK
(data), `[F.]` FIN, `[R]` reset.

## Learning objectives

After this module you can:

- Explain what packet capture is, that tcpdump needs root, and read a tcpdump
  output line — timestamp, source and destination, protocol, flags, length.
- Capture live on a chosen interface with `-i`, limit the run with `-c`, and
  suppress name lookups with `-n` / `-nn`.
- Write a BPF filter from `host` / `net` / `port` / protocol primitives joined
  with `and` / `or` / `not`, and exclude your own SSH session.
- Inspect packet contents with `-A`, `-X`, and `-e`.
- Save a capture with `-w` and re-read or hand off a `.pcap` with `-r`.
- Explain why an unfiltered capture on a busy link drops packets, and what a
  `.pcap` file can leak.

## Before you start

This module assumes you know that TCP, UDP, and ICMP exist, what a port and an
IP address are, and roughly what a TCP handshake is (SYN, SYN-ACK, ACK). The
`ss` module (what is listening) and the firewall modules (what is dropped) are
the companions to this one. You need a shell and `sudo`.

The playground is a single VM (`astrona ssh tcpdump-capture-playground`) with
**steady traffic on the loopback interface `lo`**, generated every ~2 seconds:

- an HTTP `GET http://127.0.0.1:8080/`,
- an ICMP echo to `127.0.0.1`,
- a UDP datagram to `127.0.0.1:9999` — a closed port, so an ICMP
  port-unreachable comes back.

`tcpdump`, `curl`, and `socat` are installed; `sudo` needs no password
(`tcpdump` needs root to capture). A sample capture sits at
`/usr/local/share/lab-sample.pcap`. `sudo systemctl stop lab-traffic` silences
the loop. Everything is loopback — there is no external network, and your SSH
session is not on `lo`, so `not port 22` is unnecessary here (the chapter
explains it for real interfaces).

## A first capture

`tcpdump -i <iface>` captures on one interface. `-n` stops it resolving
addresses to hostnames (faster, unambiguous, and it avoids generating DNS
lookups that then show up in your own capture); `-nn` also stops port numbers
becoming service names. `-c N` exits after N packets instead of running until
Ctrl-C.

> [!TIP]
> **Try it — five packets off the loopback**
>
> ```sh
> sudo tcpdump -i lo -n -c 5
> ```
>
> Expect a mix of the seeded traffic:
>
> ```text
> 12:00:00.100 IP 127.0.0.1.44322 > 127.0.0.1.8080: Flags [S], seq 1, win 65495, length 0
> 12:00:00.100 IP 127.0.0.1.8080 > 127.0.0.1.44322: Flags [S.], seq 1, ack 2, win 65483, length 0
> 12:00:00.100 IP 127.0.0.1.44322 > 127.0.0.1.8080: Flags [.], ack 1, win 512, length 0
> 12:00:00.100 IP 127.0.0.1.44322 > 127.0.0.1.8080: Flags [P.], seq 1:88, ack 1, length 87: HTTP: GET /?t=... HTTP/1.1
> 12:00:01.200 IP 127.0.0.1 > 127.0.0.1: ICMP echo request, id 5, seq 1, length 64
> ```
>
> The first three lines are a TCP handshake (`[S]`, `[S.]`, `[.]`); the fourth
> carries the HTTP request; the fifth is the ICMP ping. Timestamps, ports, and
> sequence numbers vary every run.

## Filtering: the BPF expression

The last argument to `tcpdump` is a **filter expression**, compiled to BPF
bytecode and run **in the kernel** — non-matching packets are dropped before
tcpdump ever sees them. The primitives:

- **`host X`**, **`net X/Y`** — an address or subnet (add `src` / `dst` to fix
  the direction: `dst host X`).
- **`port N`**, **`portrange A-B`** — a port (again `src port` / `dst port`).
- **`tcp`**, **`udp`**, **`icmp`**, **`arp`**, **`ip6`** — a protocol.

Combine them with **`and`**, **`or`**, **`not`**, grouped with parentheses.

> [!TIP]
> **Try it — one protocol at a time**
>
> ```sh
> sudo tcpdump -i lo -n -c 4 icmp
> ```
>
> Expect only ICMP — the echo requests, replies, and the port-unreachables from
> the UDP datagrams:
>
> ```text
> 12:00:02.000 IP 127.0.0.1 > 127.0.0.1: ICMP echo request, id 5, seq 3, length 64
> 12:00:02.000 IP 127.0.0.1 > 127.0.0.1: ICMP echo reply, id 5, seq 3, length 64
> 12:00:02.001 IP 127.0.0.1 > 127.0.0.1: ICMP 127.0.0.1 udp port 9999 unreachable, length 36
> ```
>
> Swap `icmp` for `tcp port 8080` to see just the HTTP conversation, or `udp` for
> just the datagrams. `tcp port 8080 and src host 127.0.0.1` narrows further.

## Excluding traffic with `not`

The most important exclusion in practice is your own SSH session. Capturing on
the interface you are connected through **without** filtering it out means every
packet tcpdump prints travels to your terminal as more output — which is itself
more packets on that interface, which tcpdump captures and prints. `not port 22`
breaks that loop. The same idea removes any noise you do not care about.

> [!TIP]
> **Try it — everything except ICMP**
>
> ```sh
> sudo tcpdump -i lo -n -c 6 'not icmp'
> ```
>
> Expect only the TCP (HTTP) and UDP packets — no echo requests or
> unreachables:
>
> ```text
> 12:00:03.000 IP 127.0.0.1.44330 > 127.0.0.1.8080: Flags [S], seq 1, length 0
> 12:00:03.000 IP 127.0.0.1.51000 > 127.0.0.1.9999: UDP, length 10
> ```
>
> On a real server that expression is more often
> `sudo tcpdump -i eth0 -n 'not port 22'` — capture everything the box is doing
> *except* the session you are typing in. Quote the expression when it contains
> parentheses or shell metacharacters.

## Seeing the packet contents

By default tcpdump prints headers, not payload. To see inside:

- **`-A`** — print the payload as ASCII. Good for text protocols (HTTP, SMTP).
- **`-X`** — hex and ASCII side by side, from the IP header up. `-XX` includes
  the link-layer header.
- **`-e`** — print the link-layer (Ethernet) header: source and destination MAC,
  ethertype, VLAN tag. (On `lo` there is no real Ethernet header, so this is
  less interesting there than on a physical NIC.)

> [!TIP]
> **Try it — read the HTTP request text**
>
> ```sh
> sudo tcpdump -i lo -n -c 10 -A 'tcp port 8080'
> ```
>
> Among the handshake packets you will see the request and response lines in
> clear:
>
> ```text
> ...: Flags [P.], seq 1:88, ack 1, length 87
> GET /?t=1710000000 HTTP/1.1
> Host: 127.0.0.1:8080
> User-Agent: curl/8.5.0
> ...
> ...: Flags [P.], seq 1:156, ack 88, length 155
> HTTP/1.0 200 OK
> ```
>
> Plain HTTP is fully readable in a capture — which is exactly why credentials
> and tokens must never travel over unencrypted connections, and why a `.pcap`
> is sensitive.

## Writing and reading `.pcap` files

`-w <file>` writes the raw packets to a file instead of decoding them to the
screen (so `-w` prints almost nothing — that is normal). `-r <file>` reads such
a file back and decodes it, and **reading needs no root**. This split lets you
capture quickly with a loose filter and analyse at leisure — with another
`tcpdump -r … <filter>`, or in Wireshark on another machine.

> [!TIP]
> **Try it — capture to a file, then read it back**
>
> ```sh
> sudo tcpdump -i lo -n -c 20 -w /tmp/cap.pcap
> tcpdump -n -r /tmp/cap.pcap | head
> ```
>
> The first command prints only a packet count; the second decodes the file:
>
> ```text
> 20 packets captured
> ```
>
> ```text
> 12:00:05.000 IP 127.0.0.1.44340 > 127.0.0.1.8080: Flags [S], ...
> ...
> ```
>
> A pre-made sample is also on the box — `tcpdump -n -r
> /usr/local/share/lab-sample.pcap | head` reads it the same way. `.pcap` is a
> standard format; the same file opens in Wireshark unchanged.

## Controlling the output

A few more flags shape what you see, without changing what is captured:

- **`-v` / `-vv` / `-vvv`** — increasing header detail (IP TTL and id, TCP
  options, checksum verification).
- **`-tttt`** — a full date and time on each line; **`-ttt`** — delta since the
  previous packet (useful for spotting a one-second retransmission gap).
- **`-s N`** — *snap length*: capture only the first N bytes of each packet.
  `-s 96` keeps headers and drops most payload, for smaller files. Modern
  tcpdump captures the whole packet by default; if payload looks truncated on an
  old system, set `-s 0`.
- **`-D`** — list the interfaces tcpdump can capture on.

## Where this fits

tcpdump shows Layers 2–4 as they actually are, which makes it the tie-breaker
when higher-level tools disagree. Pair it with `ss` ("the process says it is
listening — is a SYN even arriving?"), with the firewall modules (capture on
*both* sides of a filter to see where a packet is dropped), and with `dig`
("what DNS query did the resolver actually send?"). Wireshark is the graphical
analyser with deep protocol dissectors; `tshark` is its CLI; `tcpdump` is the
one that is already installed on the server at 3 a.m. Capturing traffic can also
expose passwords, session tokens, and personal data — only capture on systems
you are authorised to, and treat `.pcap` files as sensitive.

> [!WARNING]
> **Common pitfalls**
>
> - **No `-n` / `-nn`.** tcpdump does reverse-DNS and service-name lookups that
>   slow the output and generate their own traffic, which then appears in the
>   capture. Always use `-n` (or `-nn`) for diagnostics.
> - **Capturing your own SSH session unfiltered.** Each printed packet becomes
>   more terminal output, more packets, more captured output — a feedback loop.
>   Add `not port 22` (or the port you connected on).
> - **`-w file` and expecting decoded output.** `-w` writes binary and prints
>   only a counter. Use `-r` to read it, or drop `-w` to watch live.
> - **Unquoted filter expressions.** `tcpdump tcp and (port 80 or port 443)`
>   trips the shell on the parentheses. Quote the whole expression.
> - **Assuming a truncated-looking payload is real.** Old tcpdump defaulted to a
>   short snap length. On a modern one it is the full packet; if not, `-s 0`.
> - **Unfiltered capture on a busy interface.** tcpdump cannot keep up and
>   prints "N packets dropped by kernel" — an incomplete picture. Narrow the
>   filter, or `-w` a raw file and analyse offline.
> - **Running as a normal user.** "You don't have permission to capture on that
>   device." Capturing needs root or `CAP_NET_RAW`; *reading* a `.pcap` does not.
