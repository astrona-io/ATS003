# Question

Solve this question on: `terminal`

## Scenario

This is the Section 030 capstone — one integrated nftables policy, no
step-by-step guidance.

This host needs a hand-built `nftables` policy. The ruleset is currently
empty. You will build a filter table for inbound and outbound rules, and a
NAT table for one port redirect. A local service is already listening on
port `6001` as the redirect target.

All rules must be live in the running ruleset (`sudo nft list ruleset`).

## Tasks

1. **Drop inbound port 5000.** In an `inet` family table named `filter`,
   with an `input` chain hooked to `input`, drop all TCP traffic to
   `dport 5000`.

2. **Redirect inbound port 6000 → 6001.** In an `ip` family table named
   `nat`, with a `prerouting` chain hooked to `prerouting`, redirect TCP
   `dport 6000` to port `6001` on this host.

3. **Restrict port 6002 by source.** In the `inet filter input` chain,
   accept TCP `dport 6002` **only** from source address `192.168.10.80`,
   and drop `dport 6002` from everyone else. The accept rule must come
   **before** the catch-all drop (nftables reads top to bottom).

4. **Block egress to a host.** In an `output` chain of the `inet filter`
   table, hooked to `output`, drop all traffic whose destination address is
   `192.168.10.70`.
