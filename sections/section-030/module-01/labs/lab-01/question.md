# Question

Solve this question on: `terminal`

## Scenario

Astronaut, this training ship has no shields yet. Its nftables ruleset is
empty, and you must program it by hand. You will build a filter table for
incoming and outgoing traffic, and a NAT (network address translation)
table for one port redirect. A small local service is already listening on
port `6001`; it is the target of the redirect.

Every rule must be live in the running ruleset, so `sudo nft list ruleset`
shows it.

## Tasks

1. **Drop incoming port 5000.** In an `inet` family table named `filter`,
   with an `input` chain hooked to `input`, drop all TCP traffic to
   `dport 5000`.

2. **Redirect incoming port 6000 to 6001.** In an `ip` family table named
   `nat`, with a `prerouting` chain hooked to `prerouting`, redirect TCP
   `dport 6000` to port `6001` on this host.

3. **Limit port 6002 to one source.** In the `inet filter input` chain,
   accept TCP `dport 6002` **only** from the source address
   `192.168.10.80`, and drop `dport 6002` from everyone else. The accept
   rule must come **before** the drop rule, because nftables reads a chain
   from the top down.

4. **Block outgoing traffic to one host.** In an `output` chain of the
   `inet filter` table, hooked to `output`, drop all traffic whose
   destination address is `192.168.10.70`.

## Notes

- The checker reads each rule as one line of `sudo nft list ruleset`. Keep
  each rule to its match and its verdict, with no `counter` or `log` added.
  In the port 6002 accept rule, write the port match before the source
  address match.
- The rules only need to be live. They do not need to survive a reboot.

## Observe packets through the rules

Bootstrap creates a private client network namespace named `nft-client`, connected to this VM at `192.168.10.1`. Its source addresses are `192.168.10.80` (allowed), `192.168.10.81` (denied), and `192.168.10.70` (blocked egress destination). The management network stays separate.

```sh
sudo ip netns exec nft-client curl --max-time 3 http://192.168.10.1:6000/
sudo ip netns exec nft-client curl --interface 192.168.10.80 --max-time 3 http://192.168.10.1:6002/
sudo ip netns exec nft-client curl --interface 192.168.10.81 --max-time 3 http://192.168.10.1:6002/
```

The redirect request should reach the 6001 listener. The allowed source should reach 6002; the other source should time out. The grader also tests 5000 and egress traffic, using working control listeners so an absent service cannot masquerade as a firewall drop. Counters and equivalent rule ordering are accepted when the required packet behavior is correct.
