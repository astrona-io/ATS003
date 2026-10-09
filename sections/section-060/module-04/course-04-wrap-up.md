# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part of this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about tcpdump: the recorder clipped onto an antenna, and the `.pcap` tape it writes.

**From [Your First Capture](./course-01-first-capture.md):**

- Packet capture records copies of real frames on an interface. tcpdump needs root to capture and uses promiscuous mode by default.
- A line reads: timestamp, protocol, source and port, destination and port, TCP (Transmission Control Protocol) flags, sequence, window, length.
- `[S]` is SYN, `[S.]` SYN-ACK, `[P.]` data, `[F.]` FIN, `[R]` reset.
- `-i` picks the interface, `-n` stops name lookups, `-c N` stops after N packets.

**From [Filter The Capture](./course-02-filter-the-capture.md):**

- The filter is the last argument and runs in the kernel as BPF code.
- Primitives are `host`, `net`, `port`, `portrange` and protocols such as `tcp`, `udp`, `icmp`, joined with `and`, `or` and `not`.
- On the interface you are connected through, add `not port 22` to stop the feedback loop. Quote the expression.

**From [Look Inside And Save The Tape](./course-03-contents-and-files.md):**

- `-A` prints the payload as text, `-X` as hex and text, and `-e` adds the link-layer header.
- `-w` writes a `.pcap` file and prints only a count; `-r` reads it back, without root.
- `-v`, `-tttt`, `-ttt`, `-s` and `-D` shape the output and the capture size.
- A capture of plain HTTP (Hypertext Transfer Protocol) shows everything, so `.pcap` files are sensitive.

## Your missions

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Raw Packet Capturing (tcpdump) Lab](./labs/lab-01/README.md) | Look Inside And Save The Tape | confirm a reachable listener, remove the firewall rule that blocks it, and prove it answers |

If you skipped it, go back to it now. It is short, and the exam asks for exactly this kind of diagnosis.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. What does <code>Flags [S.]</code> mean in a tcpdump line?</summary>

It is a SYN-ACK: the server's answer to a connection request.
</details>

<details>
<summary>2. You capture on <code>eth0</code> while connected over SSH on that interface, and the output never stops. What do you add?</summary>

`'not port 22'` (or the port you connected on). It stops tcpdump from recording the packets that carry its own output.
</details>

<details>
<summary>3. You ran <code>sudo tcpdump -i lo -n -c 20 -w /tmp/cap.pcap</code> and saw almost nothing. Did it fail?</summary>

No. `-w` writes the packets to the file and prints only a count. Read it with `tcpdump -n -r /tmp/cap.pcap`.
</details>

<details>
<summary>4. Which option prints the text of an HTTP request inside the packets?</summary>

`-A`, which prints the payload as ASCII. `-X` shows it as hex and ASCII side by side.
</details>

<details>
<summary>5. tcpdump reports "packets dropped by kernel". What does it mean, and what do you do?</summary>

tcpdump could not keep up, so the capture is incomplete. Narrow the filter, or write to a file with `-w` and analyse it later.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy tcpdump-capture-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-064
```

Then run `astrona list` once more and check that neither name appears any longer.

You can start the playground again at any time with the `astrona run` command for this module's playground. It always starts clean, so nothing you changed carries over.
