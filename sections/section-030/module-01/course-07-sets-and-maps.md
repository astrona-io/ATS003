# Sets And Maps

Astronaut, a shield program with fifty nearly identical lines is hard to read and slow to change. **Sets** and **maps** fold those lines into one. With a named set you change what is allowed by editing a list, not by editing rules.

This part shows sets first, then maps and verdict maps.

## Sets: one rule for many values

A **set** is a named list of values of one type that a single rule matches against. This section shows how to build one, the two kinds of set, and the flags that make them more useful.

### From three rules to one

Instead of three rules:

```sh
sudo nft add rule inet filter input tcp dport 22 accept
sudo nft add rule inet filter input tcp dport 80 accept
sudo nft add rule inet filter input tcp dport 443 accept
```

you write one rule and a set:

```sh
sudo nft add set inet filter allowed_tcp '{ type inet_service ; }'
sudo nft add element inet filter allowed_tcp '{ 22, 80, 443 }'
sudo nft add rule inet filter input tcp dport @allowed_tcp accept
```

`@name` in a rule means "look this up in the set". The **type** of a set's elements can be `ipv4_addr`, `ipv6_addr`, `inet_service` (a port), `ether_addr` (a MAC address, the antenna's serial number) or `mark`.

### Anonymous and named sets

- An **anonymous set** is written inline with no name: `tcp dport { 22, 80, 443 } accept`. You cannot change it without editing the rule. It is fine for a list that never changes.
- A **named set** is created on its own and used with `@name`. You can `add element` and `delete element` while it runs, **without touching any rule**. This is how you keep a live allow list or block list.

### Useful set flags

- `flags interval` lets elements be ranges or whole networks: `{ 192.168.0.0/16, 10.0.0.0/8 }`.
- `flags timeout` with `timeout 1h` makes elements expire on their own. Combine it with a rule that does `add @blocklist { ip saddr timeout 10m }`, and the ruleset fills its own block list as traffic arrives, a simple home-made version of the `fail2ban` tool.

## Change a set while it runs

See a named set open a port on your playground without any rule being edited. You need a table, a base chain, and two small web servers.

### Build the chain and the set

<!-- astrona:playground:renew -->

Start with a clean, default-deny `input` chain that keeps your SSH (Secure Shell, the sealed communications channel between ships) session and established traffic alive. There is no `iif "lo" accept` rule this time, so the set alone decides which local ports answer:

```sh
sudo nft flush ruleset
sudo nft add table inet filter
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy drop ; }'
sudo nft add rule inet filter input ct state established,related accept
sudo nft add rule inet filter input tcp dport 22 accept
```

### Allow a group of ports, then change the group

```sh
sudo nft add set inet filter webports '{ type inet_service ; }'
sudo nft add element inet filter webports '{ 5000 }'
sudo nft add rule inet filter input tcp dport @webports accept
python3 -m http.server 5000 &
curl -sS --max-time 3 http://127.0.0.1:5000/ | head -c 30 ; echo    # works: 5000 is in the set
curl -sS --max-time 3 http://127.0.0.1:5001/ ; echo "exit: $?"      # fails: 5001 is not
sudo nft add element inet filter webports '{ 5001 }'
python3 -m http.server 5001 &
curl -sS --max-time 3 http://127.0.0.1:5001/ | head -c 30 ; echo    # now works — no rule was edited
```

The `accept` rule never changed. Adding `5001` to the set is what opened it. Stop the two web servers with `kill %1 %2` before you go on, so the ports are free again.

## Maps: look up a value

A **map** links a key to a value. A plain map gives back data, such as an address or a mark. A **verdict map** (`vmap`) gives back a *verdict*, so one rule can handle many cases with a single lookup instead of a long ladder of rules.

### A verdict map

```sh
sudo nft add rule inet filter input tcp dport vmap { 22 : accept, 80 : accept, 3306 : drop }
```

That one rule accepts ports 22 and 80 and drops 3306. A port that is not a key falls through to the next rule. Named verdict maps can be changed while they run, just like sets, and they can send packets to chains: `iifname vmap { "eth0" : jump wan_in, "eth1" : jump lan_in }`.

### Send ports to verdicts with one rule

```sh
sudo nft flush ruleset
sudo nft add table inet filter
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'
sudo nft add rule inet filter input tcp dport vmap { 5000 : drop, 5001 : accept }
python3 -m http.server 5000 & python3 -m http.server 5001 &
curl -sS --max-time 3 http://127.0.0.1:5000/ ; echo "exit: $?"        # dropped
curl -sS --max-time 3 http://127.0.0.1:5001/ | head -c 30 ; echo      # accepted
```

One rule gives two different verdicts, chosen by port. There is no `iif "lo" accept` rule in this chain on purpose: it would accept the loopback test traffic before the verdict map is ever read. Clean up with `sudo nft flush ruleset`.

## Common pitfalls

> [!WARNING]
> - **Editing rules to change a list.** Use a named set; `add element` and `delete element` change it with no rule edits.
> - **Ranges in a set without `flags interval`.** A set needs that flag before it accepts networks or ranges.
> - **Expecting a verdict map to cover every case.** A key that is not in the map falls through to the next rule and, in the end, to the chain's policy.

> *Named sets and verdict maps let you change what is allowed by editing data, not rules.*
