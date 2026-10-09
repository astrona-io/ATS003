# Filter The Capture

Astronaut, a recorder that keeps everything soon fills its tape with noise. In this part you tell tcpdump exactly which signals to keep, and which to leave out, using a filter expression.

## Filtering: the BPF expression

The filter is the last argument on the tcpdump line. The kernel runs it, so packets that do not match never reach tcpdump at all.

### The primitives

- **`host X`**, **`net X/Y`**: an address or a subnet. Add `src` or `dst` to fix the direction, as in `dst host X`.
- **`port N`**, **`portrange A-B`**: a port, again with `src port` or `dst port` if you need a direction.
- **`tcp`**, **`udp`**, **`icmp`**, **`arp`**, **`ip6`**: a protocol.

Combine them with **`and`**, **`or`** and **`not`**, grouped with parentheses.

### One protocol at a time

<!-- astrona:playground:renew -->

Capture four ICMP (Internet Control Message Protocol, the short status signals such as ping) packets:

```sh
sudo tcpdump -i lo -n -c 4 icmp
```

Expect only ICMP: the echo requests, the replies, and the port-unreachables caused by the UDP (User Datagram Protocol, single signal bursts with no confirmation) datagrams:

```text
12:00:02.000 IP 127.0.0.1 > 127.0.0.1: ICMP echo request, id 5, seq 3, length 64
12:00:02.000 IP 127.0.0.1 > 127.0.0.1: ICMP echo reply, id 5, seq 3, length 64
12:00:02.001 IP 127.0.0.1 > 127.0.0.1: ICMP 127.0.0.1 udp port 9999 unreachable, length 36
```

Swap `icmp` for `tcp port 8080` to see only the HTTP (Hypertext Transfer Protocol, the language of web requests) conversation, or for `udp` to see only the datagrams. `tcp port 8080 and src host 127.0.0.1` narrows it further.

## Leaving traffic out with `not`

The most important exclusion in real life is your own SSH (Secure Shell, a sealed communications channel between two ships) session. Without it, the capture feeds on itself.

### The feedback loop

Suppose you capture on the interface you are connected through, without filtering your session out. Every packet tcpdump prints travels to your terminal as more output. That output is more packets on the same interface, which tcpdump captures and prints, and so on. `not port 22` breaks that loop. The same idea removes any noise you do not care about.

### Everything except ICMP

Capture six packets that are not ICMP:

```sh
sudo tcpdump -i lo -n -c 6 'not icmp'
```

Expect only the TCP (HTTP) and UDP packets, with no echo requests or unreachables:

```text
12:00:03.000 IP 127.0.0.1.44330 > 127.0.0.1.8080: Flags [S], seq 1, length 0
12:00:03.000 IP 127.0.0.1.51000 > 127.0.0.1.9999: UDP, length 10
```

On a real server the expression is more often `sudo tcpdump -i eth0 -n 'not port 22'`: record everything the machine does *except* the session you are typing in.

> [!TIP]
> Quote the whole filter expression whenever it contains spaces, parentheses or other characters the shell treats specially. Then the shell passes it to tcpdump untouched.

## Common pitfalls

> [!WARNING]
> - **Capturing your own SSH session unfiltered.** Each printed packet becomes more terminal output, more packets and more captured output: a feedback loop. Add `not port 22` (or the port you connected on).
> - **Unquoted filter expressions.** `tcpdump tcp and (port 80 or port 443)` trips the shell on the parentheses. Quote the whole expression.
> - **Unfiltered capture on a busy interface.** tcpdump cannot keep up and prints "N packets dropped by kernel", so the picture is incomplete. Narrow the filter, or write a raw file with `-w` and analyse it later.
