# Follow The Path

Astronaut, when the local rungs are fine and the target is on another ship, you need to see the lane between. These tools send probe signals and report who answered. They tell you where along the lane the signal dies.

## ping: is anyone there?

`ping` sends small ICMP (Internet Control Message Protocol) echo requests and waits for replies. It is the quickest "hello" and it measures the round-trip time.

### See it in your playground

<!-- astrona:playground:renew -->

Send four probes to the address of `lab0`:

```sh
ping -c 4 10.66.0.10
```

Every probe should get a reply. `-c 4` stops after four. A few useful options are `-I <interface>` to send from a chosen antenna, `-W 2` to wait only two seconds per reply, and `-s 1400 -M do` to test a large packet that must not be split.

A reply proves that the lanes and the far ship work for ICMP. It does not prove that a TCP port is open, because a firewall can treat ICMP and TCP differently.

## traceroute and tracepath: which hops?

`traceroute` sends probes with a rising time-to-live (TTL) value. Each relay ship that lowers the TTL to zero reports back, so you see every hop in order. `tracepath` does the same without needing root and also reports the path MTU (the largest packet that fits).

### Read the output

```sh
traceroute -n 10.66.0.10
tracepath -n 10.66.0.10
```

`-n` skips name lookups, so the command does not stall on DNS. Because the target is a local address, you get one hop. On a real path each line is one relay with three round-trip times. A line with `* * *` means the relay did not answer. That is often a firewall that drops the probes, not a broken lane, so keep reading the lines below it.

If `traceroute` is missing on your ship, install it with `sudo apt install traceroute`. The playground tries to install it for you.

## mtr: a moving picture

`mtr` combines `ping` and `traceroute`. It keeps probing every hop and shows loss and delay per hop. In report mode it runs a fixed number of rounds and prints one table.

### Run a report

```sh
mtr -rwn -c 5 10.66.0.10
```

`-r` is report mode, `-w` shows full host names or addresses, `-n` skips name lookups and `-c 5` sends five probes per hop. Read the `Loss%` column from the bottom up. Loss that appears at a middle hop but not at the last hop is almost always a relay that rate-limits its own replies, not real loss. Loss that continues to the last hop is real.

## Common pitfalls

> [!WARNING]
> - **Reading `* * *` as a broken lane.** Many relays do not answer probes, but still pass traffic. Look at the later hops.
> - **Believing a silent `ping` means the ship is down.** Many networks drop ICMP. Test the real port with `curl` or `nc`.
> - **Forgetting `-n`.** Name lookups slow the command down when DNS is the thing that is broken.
> - **Blaming a middle hop.** Real loss shows at the last hop too.
