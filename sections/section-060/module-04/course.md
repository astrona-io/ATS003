# Raw Packet Capturing (tcpdump)

Astronaut, logs tell you what a crew member *says* happened. A recorder clipped onto an antenna tells you what really went out and what really came back. That recorder is **tcpdump**, and its tape is a `.pcap` file. When a connection times out or gets refused and the logs do not explain why, a capture shows the ground truth.

## Learning objectives

After this module you can:

- Explain what packet capture is, why tcpdump needs root, and read a tcpdump output line: timestamp, source and destination, protocol, flags and length.
- Capture live on a chosen interface with `-i`, limit the run with `-c`, and switch off name lookups with `-n` or `-nn`.
- Write a BPF filter from `host`, `net`, `port` and protocol primitives joined with `and`, `or` and `not`, and leave out your own SSH (Secure Shell, a sealed communications channel between two ships) session.
- Look inside packets with `-A`, `-X` and `-e`.
- Save a capture with `-w`, and read a `.pcap` file back with `-r`.
- Explain why an unfiltered capture on a busy link drops packets, and what a `.pcap` file can leak.

## Before you start

A short pre-flight check: the knowledge this module expects, and what is waiting in your playground.

### What you should already know

- **Protocols and ports.** What an IP (Internet Protocol) address is (the ship's call sign) and what a port is. That TCP (Transmission Control Protocol, a channel where both sides confirm every signal), UDP (User Datagram Protocol, single signal bursts with no confirmation) and ICMP (Internet Control Message Protocol, short status signals such as ping) exist. Roughly what a TCP handshake is (SYN, SYN-ACK, ACK).
- **The shell.** You can open a shell and use `sudo`.

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine. Open a shell on it with `astrona ssh tcpdump-capture-playground`.

- **Steady traffic on the loopback interface `lo`**, sent about every 2 seconds by `lab-traffic.service`:
  - an HTTP (Hypertext Transfer Protocol, the language of web requests) `GET http://127.0.0.1:8080/` (served by `lab-http.service`),
  - an ICMP echo to `127.0.0.1`,
  - a UDP datagram to `127.0.0.1:9999`, a closed port, so an ICMP port-unreachable comes back.
- A **sample capture** at `/usr/local/share/lab-sample.pcap`, so `tcpdump -r` has a file to read from the first minute.
- `tcpdump`, `curl`, `python3`, `socat` and `ping` are installed. `sudo` needs no password, and `tcpdump` needs root to capture.

Everything happens on `lo`; there is no external network. Your SSH session is not on `lo`, so you do not need to filter it out here. `sudo systemctl stop lab-traffic` silences the loop if you want a quiet interface.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Your First Capture](./course-01-first-capture.md): what capture is, how to read a tcpdump line, and five packets off the loopback.
2. [Filter The Capture](./course-02-filter-the-capture.md): BPF primitives, one protocol at a time, and leaving traffic out with `not`.
3. [Look Inside And Save The Tape](./course-03-contents-and-files.md): payload with `-A` and `-X`, `.pcap` files, and flags that shape the output.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, a self-check and cleanup.

## Why this matters

When `ss` says a service listens and the firewall looks fine, but clients still time out, only a capture shows whether the packets arrive and whether anything answers. It is the tool that settles arguments between the other tools, and it is already installed on most servers.
