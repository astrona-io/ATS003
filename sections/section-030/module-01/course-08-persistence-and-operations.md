# Persistence And Operating A Ruleset

Astronaut, everything `nft` changes is chalked on the console: it lives only in the running kernel and is gone at the next restart. This part is about writing the shield program into the flight manual so it survives a reboot.

It also covers loading a whole ruleset in one step from a file, watching it work in real time, and checking which tool owns the shields before you touch them.

## Runtime state and persistent configuration

There is no automatic save in nftables. This section shows what a reboot does to your rules, and the two pieces that bring them back.

### What a reboot does

Every `nft add`, `delete` and `flush` edits the **running kernel ruleset** and nothing else. A reboot clears all of it: tables, chains, rules, sets and counters.

### The file and the service

Keeping a ruleset takes two pieces:

1. A **file** that holds the ruleset in `nft` script syntax.
2. A **systemd service** (a station the ship's duty officer starts at boot) that loads that file.

On Debian and Ubuntu the file is `/etc/nftables.conf` and the service is `nftables.service`:

```sh
sudo nft list ruleset | sudo tee /etc/nftables.conf   # snapshot current runtime state to the file
sudo systemctl enable --now nftables.service          # load it now and on every boot
```

`nft -f /etc/nftables.conf` loads such a file by hand at any time. The playground leaves `nftables.service` **disabled**, so nothing you build survives a restart unless you set this up.

## Prove that rules vanish on reboot

See it once with your own eyes. This restarts the playground machine and drops your SSH (Secure Shell, the sealed communications channel between ships) session for about a minute.

### Add a rule and reboot

<!-- astrona:playground:renew -->

```sh
sudo nft add table inet filter
sudo nft 'add chain inet filter input { type filter hook input priority 0 ; policy accept ; }'
sudo nft add rule inet filter input tcp dport 5000 drop
sudo reboot
```

Reconnect with `astrona ssh nftables-filtering-playground`.

### Look again after the reboot

```sh
sudo nft list ruleset
```

There is no output. The table, the chain and the rule are gone, and you are back to the empty ruleset the machine started with. Anything that must come back after a reboot has to be in `/etc/nftables.conf`, with the service enabled.

## Load a whole ruleset in one step

Adding rules one `nft` command at a time means the ruleset passes through every half-built state on the way. If command 7 of 12 sets `policy drop` before command 9 adds the SSH `accept`, you are locked out in the gap. Loading a file avoids that.

### Atomic loading with `nft -f`

`nft -f file` applies the **whole file in one transaction**. nftables reads all of it, and either everything goes live at once, or nothing changes and you get an error with a line number. The running ruleset never shows a half-built state. This is called an atomic load.

### Write and load a ruleset file

Save this as `/etc/nftables.conf`:

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

Check it without applying it (`-c` means check the syntax only):

```sh
sudo nft -c -f /etc/nftables.conf
```

Apply it:

```sh
sudo nft -f /etc/nftables.conf
```

Then check the result with `sudo nft list ruleset`: you should see the `inet filter` table with its three chains. Your SSH session stays up, because port 22 and established traffic are accepted.

### Why this file is safe

- `flush ruleset` at the top means every load fully replaces the old ruleset, so no old rules are left behind.
- Because the load is atomic, `policy drop` above the `accept` rules in the file is **safe**: the kernel never runs the chain until the whole table is in place.
- You can define names and reuse pieces: `define admin_net = 192.168.80.0/24`, then `ip saddr $admin_net accept`; and `include "/etc/nftables.d/*.conf"` splits a large ruleset over several files.

## Watch a live ruleset

Once rules are live, you need ways to read them and to see what they do to real traffic. These commands cover both:

| Command | Use |
|---|---|
| `nft list ruleset` | full dump in script syntax |
| `nft -a list ruleset` | the same, with `# handle N` on every object; needed for `delete` and `replace` |
| `nft -s list ruleset` | "stateless": leaves out counter values, for comparing files |
| `nft -j list ruleset` | JSON output, for scripts and tools |
| `nft monitor` | shows ruleset changes as they happen (who is editing the firewall) |
| `nft monitor trace` | with a `meta nftrace set 1` rule in place, prints the rule-by-rule path of matching packets |

`nftrace` is the closest thing nftables has to a debugger:

```sh
sudo nft add rule inet filter input ip saddr 192.168.80.10 meta nftrace set 1
sudo nft monitor trace          # in one session
# generate traffic from 192.168.80.10 in another — every rule it touches is printed
```

## Check who owns the shields

Hand-written rules are not the only rules on many machines. Before you add any, find out what else manages the ruleset. This section lists the usual owners.

### Distribution differences

- **Debian and Ubuntu:** `/etc/nftables.conf` and `nftables.service`, as above. `ufw` is a common front end; if it is active, let it own the ruleset.
- **Red Hat Enterprise Linux, Fedora and CentOS Stream:** `firewalld` is installed and enabled by default and owns the nftables ruleset. On those systems you change the firewall through `firewall-cmd`, not by hand-editing `nft` rules, because firewalld rebuilds its table on every reload.
- The `nftables-services` and `iptables` compatibility packages keep old `iptables` scripts working. Underneath, they write nftables rules into an `ip`-family table called `filter`.

### Filtering protects services; it does not create them

The shields do not replace the rest of the network stack. A port only answers if a program is listening on it; nftables can block or allow *reaching* a service, not create one.

On many systems a higher-level tool, such as `firewalld`, `ufw`, or a cloud provider's security groups, already manages nftables for you, and hand-written rules can clash with what it expects. Check what is managing the ruleset before you add rules by hand.

## Common pitfalls

> [!WARNING]
> - **Building a ruleset with many separate `nft` commands on a remote host.** Every half-built state goes live. Write it in a file and apply it with `nft -f`.
> - **Expecting rules to survive a reboot.** `nft` changes are runtime only. Persistence is `/etc/nftables.conf` plus an enabled `nftables.service`, or your distribution's front end.
> - **Hand-editing `nft` on a host run by `firewalld` or `ufw`.** The front end overwrites the ruleset on its next reload. Use the front end's own commands.
> - **Loading a file without checking it.** Run `sudo nft -c -f` first; a syntax error tells you the line number and changes nothing.

> *`nft` changes are runtime only; persistence is a file plus an enabled service. Load that file with `nft -f` so the whole ruleset goes live in one transaction and never half-built.*
