# Look Inside And Save The Tape

Astronaut, headers tell you who talked to whom. Sometimes you need to hear what they said, or keep the tape to study later. This part shows how to print packet contents, save a capture to a `.pcap` file, read it back, and shape the output.

## Seeing the packet contents

By default tcpdump prints headers, not the payload. Three options let you see inside.

### The content options

- **`-A`** prints the payload as ASCII text. Good for text protocols such as HTTP (Hypertext Transfer Protocol, the language of web requests) and SMTP.
- **`-X`** prints hex and ASCII side by side, from the IP header up. `-XX` adds the link-layer header.
- **`-e`** prints the link-layer (Ethernet) header: source and destination MAC address (the antenna's serial number), ethertype and VLAN tag. On `lo` there is no real Ethernet header, so it shows less there than on a physical interface.

### Read the HTTP request text

<!-- astrona:playground:renew -->

Capture ten packets on port 8080 and print their payload:

```sh
sudo tcpdump -i lo -n -c 10 -A 'tcp port 8080'
```

Among the handshake packets you see the request and response lines in plain text:

```text
...: Flags [P.], seq 1:88, ack 1, length 87
GET /?t=1710000000 HTTP/1.1
Host: 127.0.0.1:8080
User-Agent: curl/8.5.0
...
...: Flags [P.], seq 1:156, ack 88, length 155
HTTP/1.0 200 OK
```

Plain HTTP is fully readable in a capture. That is exactly why passwords and tokens must never travel over unencrypted connections, and why a `.pcap` file is sensitive.

## Writing and reading `.pcap` files

`-w <file>` writes the raw packets to a file instead of printing them, so tcpdump shows almost nothing on screen. That is normal. `-r <file>` reads such a file back and decodes it.

### Capture now, study later

**Reading needs no root.** This split lets you capture quickly with a loose filter and study the tape at your own pace, with another `tcpdump -r … <filter>` or in Wireshark on another machine.

### Capture to a file, then read it back

Record twenty packets to a file, then decode the first lines:

```sh
sudo tcpdump -i lo -n -c 20 -w /tmp/cap.pcap
tcpdump -n -r /tmp/cap.pcap | head
```

The first command prints only a packet count; the second decodes the file:

```text
20 packets captured
```

```text
12:00:05.000 IP 127.0.0.1.44340 > 127.0.0.1.8080: Flags [S], ...
...
```

A ready-made sample is also on the machine: `tcpdump -n -r /usr/local/share/lab-sample.pcap | head` reads it the same way. `.pcap` is a standard format, so the same file opens in Wireshark unchanged.

## Controlling the output

A few more options shape what you see, without changing what is captured. They are useful when the default line hides the detail you need.

### Detail, time and size

- **`-v`, `-vv`, `-vvv`**: more header detail each time (the IP time to live (TTL) and ID, the options of TCP, the Transmission Control Protocol, and checksum checks).
- **`-tttt`**: a full date and time on each line. **`-ttt`**: the time since the previous packet, useful for spotting a one-second retransmission gap.
- **`-s N`**: the *snap length*, which captures only the first N bytes of each packet. `-s 96` keeps headers and drops most payload, for smaller files. Modern tcpdump captures the whole packet by default; if the payload looks cut off on an old system, set `-s 0`.
- **`-D`**: list the interfaces tcpdump can capture on.

## Common pitfalls

> [!WARNING]
> - **`-w file` and expecting decoded output.** `-w` writes binary and prints only a counter. Read it with `-r`, or leave out `-w` to watch live.
> - **Trusting a payload that looks cut off.** Old tcpdump versions used a short snap length by default. A modern one captures the full packet; if not, use `-s 0`.
> - **Leaving `.pcap` files lying around.** They can hold passwords, tokens and personal data. Treat them as sensitive.

## Your mission: Raw Packet Capturing (tcpdump) Lab

You can now record traffic on an interface, filter it, and read what was said. The graded mission gives you a web service on port 8080 that clients cannot reach: you confirm with `ss` that it listens on a reachable address, find and remove the firewall rule (an nftables rule, part of the ship's shields) that silently drops its traffic, and prove it answers with `curl`. A capture on port 8080 is a good way to see the packets arrive with no answer.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop tcpdump-capture-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-04/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-060/module-04/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-064
astrona start tcpdump-capture-playground
```
