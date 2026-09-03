# Part 6 — Persistence and operating a ruleset

> Prerequisite: [Part 5 — Connection tracking, sets, and maps](./course-05-conntrack-sets-maps.md). This is the last part of the module — return to [course.md](./course.md), then the [firewalld module](../module-02/course.md).

You can now build a working ruleset. This part is about keeping it: everything `nft` changes lives only in the running kernel and is gone on reboot. It also covers loading a whole ruleset atomically from a file, watching it work in real time, and the mistakes that bite people once the ruleset is live.

## Runtime state versus persistent configuration

Every `nft add`, `delete`, and `flush` edits the **running kernel ruleset** and nothing else. A reboot clears all of it — tables, chains, rules, sets, counters, the lot. There is no automatic save.

Persistence is two pieces:

1. A **file** containing the ruleset in `nft` script syntax.
2. A **systemd service** that loads that file at boot.

On Debian and Ubuntu the file is `/etc/nftables.conf` and the service is `nftables.service`:

```sh
sudo nft list ruleset | sudo tee /etc/nftables.conf   # snapshot current runtime state to the file
sudo systemctl enable --now nftables.service          # load it now and on every boot
```

`nft -f /etc/nftables.conf` loads such a file by hand at any time. The playground leaves `nftables.service` **disabled**, so nothing you build survives a restart unless you set this up.

> [!TIP]
> **Try it — confirm the ruleset does not survive a reboot**
>
> This restarts the VM and drops your SSH session for about a minute; reconnect with `astrona ssh astro-nftables-filtering-playground`.
>
> ```sh
> sudo nft add table inet filter
> sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'
> sudo nft add rule inet filter input tcp dport 5000 drop
> sudo reboot
> ```
>
> After reconnecting:
>
> ```sh
> sudo nft list ruleset
> ```
>
> Expect no output — the table, chain, and rule are gone, back to the empty ruleset from the start of the module. Anything that must return after a reboot has to be in `/etc/nftables.conf` with the service enabled.

## Loading a whole ruleset atomically

Adding rules one `nft` command at a time means the ruleset passes through every half-built intermediate state — and if command 7 of 12 sets `policy drop` before command 9 adds the SSH `accept`, you are locked out in the gap.

`nft -f file` avoids that. The **entire file is applied in one transaction**: nftables parses all of it, and either the whole thing commits at once or nothing changes and you get a parse error with a line number. The running ruleset never shows a partial state.

The standard file layout:

```nft
#!/usr/sbin/nft -f

flush ruleset                       # start from a known-empty state every load

table inet filter {
	chain input {
		type filter hook input priority 0; policy drop;

		iif "lo" accept
		ct state established,related accept
		ct state invalid drop
		tcp dport 22 accept
		tcp dport { 80, 443 } accept
		ip protocol icmp accept
	}

	chain forward {
		type filter hook forward priority 0; policy drop;
	}

	chain output {
		type filter hook output priority 0; policy accept;
	}
}
```

- `flush ruleset` at the top means every load fully replaces the old ruleset — no drift from leftover rules.
- Because the load is atomic, `policy drop` before the `accept` rules in the file is **safe** — the kernel never runs the chain until the whole table is in place.
- Test a file without committing: `sudo nft -c -f /etc/nftables.conf` (`-c` = check syntax only).
- Define constants and reuse fragments: `define admin_net = 192.168.80.0/24` then `ip saddr $admin_net accept`; `include "/etc/nftables.d/*.conf"` to split large rulesets.

## Watching a live ruleset

| Command | Use |
|---|---|
| `nft list ruleset` | full dump in script syntax |
| `nft -a list ruleset` | same, with `# handle N` on every object — needed for `delete`/`replace` |
| `nft -s list ruleset` | "stateless" — omit counter values, for diffing configs |
| `nft -j list ruleset` | JSON output, for scripts and tooling |
| `nft monitor` | stream ruleset changes as they happen (who is editing the firewall) |
| `nft monitor trace` | with a `meta nftrace set 1` rule in place, print the rule-by-rule path of matching packets |

`nftrace` is the closest thing to a debugger:

```sh
sudo nft add rule inet filter input ip saddr 192.168.80.10 meta nftrace set 1
sudo nft monitor trace          # in one session
# generate traffic from 192.168.80.10 in another — every rule it touches is printed
```

## Distribution differences

- **Debian / Ubuntu:** `nftables.conf` + `nftables.service` as above. `ufw` is the common front end; if it is active, let it own the ruleset.
- **RHEL / Fedora / CentOS Stream:** `firewalld` is installed and enabled by default and owns the nftables ruleset — the subject of the [next module](../module-02/course.md). On those systems you configure the firewall through `firewall-cmd`, not by hand-editing `nft` rules, because firewalld regenerates its table on every reload.
- The `nftables-services` / `iptables` compatibility packages let old `iptables` scripts keep working; under the hood they emit nftables rules into an `ip`-family table called `filter`.

## Common pitfalls

> [!WARNING]
>
> - **`policy drop` with no accept for SSH or established connections.** The session dies the instant the policy changes. Accept `iif "lo"`, `ct state established,related`, and your SSH port *first* — or load the whole ruleset atomically from a file so the order within the file is irrelevant.
> - **Building a ruleset with many separate `nft` commands on a remote host.** Every intermediate state goes live. Stage it in a file and apply with `nft -f`.
> - **Filtering in the `ip` family and forgetting IPv6.** Rules in an `ip` table never see IPv6 packets. Use `inet` so one ruleset covers both, or you may block a port on IPv4 while it stays open on IPv6.
> - **A chain with no hook filters nothing.** Only a *base* chain — one with `type`, `hook`, and `priority` — receives packets. A regular chain is inert until another chain does `jump` or `goto` to it.
> - **Expecting line numbers.** Rules are edited and deleted by **handle** (`nft -a list ruleset`), not by position or by retyping the rule text.
> - **Rule order.** Evaluation stops at the first `drop` or `accept`. An `accept` placed after a broader `drop` is dead code.
> - **Forgetting `ct state invalid drop`.** Without it, out-of-state packets fall through to whatever your generic rules do, sometimes getting accepted.
> - **Expecting rules to persist.** `nft` changes are runtime-only. Persistence is `/etc/nftables.conf` plus an enabled `nftables.service` — or your distro's front end.
> - **Hand-editing `nft` on a firewalld/ufw host.** The front end overwrites the ruleset on its next reload. Use the front end's own commands.

> *`nft` changes are runtime-only; persistence is a file plus an enabled service. Load that file with `nft -f` so the whole ruleset commits in one transaction and never goes live half-built.*

## Reference

- `man 8 nft`, sections "Ruleset" and "Command-line options" — `-f`, `-c`, `-a`, `-s`, `-j`, and the `include`/`define` directives.
- `man 5 nftables.conf` (Debian) — the layout and load behaviour of the system ruleset file.
- `man 8 nftables.service` / `systemctl cat nftables` — exactly what the boot-time load does.
- **netfilter.org wiki, "Scripting"** (`https://wiki.nftables.org/wiki-nftables/index.php/Scripting`) — atomic-load idioms, error handling, and multi-file rulesets.
