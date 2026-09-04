# Overview: PLAYGROUND — Packet Filtering with nftables (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server host. Reach it with
  `astrona ssh nftables-filtering-playground`.
- `nft` (the nftables userspace command), plus `ncat`, `curl`, `python3`, and
  `iproute2` for generating and watching traffic.
- **An empty ruleset.** `nft list ruleset` prints nothing until you add a
  table. There is no stock firewall to work around.
- Two local IPv4 addresses:
  - the **management interface** — carries your SSH session. Do not add a rule
    that drops traffic to it or you lock yourself out;
  - **`192.168.80.10/24`** on a local dummy interface, so you have a second
    source address for `ip saddr` rules. Find the kernel names with
    `ip -brief -4 addr show`.
- `sudo` works without a password.

## Things to try

Start a throwaway listener in one SSH session and probe it from another (or
background it with `&`):

```sh
python3 -m http.server 5000
```

- **Build the structure from scratch.** `nft add table inet filter`, then
  `nft add chain inet filter input '{ type filter hook input priority 0 ; policy accept ; }'`,
  then `nft list ruleset` to see what you made.
- **Drop a port and watch it happen.** With the listener up,
  `curl -sS --max-time 3 http://127.0.0.1:5000/` succeeds. Add
  `nft add rule inet filter input tcp dport 5000 drop`, run the `curl` again,
  and watch it time out. Delete the rule to restore it.
- **See the rule handles.** `nft -a list ruleset` prints a `# handle N` on every
  rule; `nft delete rule inet filter input handle N` removes one by handle.
- **Count instead of drop.** Add `... tcp dport 5000 counter` and re-run
  `nft list ruleset` after a few `curl`s to see the packet and byte counters
  climb.
- **Match on source address.** Add
  `nft add rule inet filter input ip saddr 192.168.80.10 tcp dport 6002 accept`
  followed by `... tcp dport 6002 drop`, start a listener on 6002, and compare
  `curl --interface 192.168.80.10 http://192.168.80.10:6002/` with a plain
  `curl http://127.0.0.1:6002/`.
- **Flip the chain policy.** Set the input chain's policy to `drop` and see
  everything except what you explicitly `accept` stop — including, if you are
  not careful, your SSH session. `nft flush ruleset` is the fast way back.
- **`nft monitor`** in one session while you add and delete rules in another.

## What this sandbox does not set up

- **Persistence.** Everything you build with `nft` lives in the kernel only; a
  reboot clears it. Making a ruleset survive reboot means writing it to
  `/etc/nftables.conf` and enabling `nftables.service` — this sandbox leaves
  that service off.
- **A second real host.** `ip saddr` rules are exercised with the VM's own two
  addresses via `curl --interface`, not traffic from another machine.
- **Anything to grade.** There is no target ruleset and no check.

## When you're done

```sh
astrona destroy nftables-filtering-playground
```

(`astrona destroy` takes the environment name, not the config path.)
