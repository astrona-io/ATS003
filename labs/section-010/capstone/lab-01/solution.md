# Solution

## Step 0: Identify the active network management stack

```bash
ip -br addr show
systemctl is-active NetworkManager 2>/dev/null
systemctl is-active systemd-networkd 2>/dev/null
ls /etc/netplan/ 2>/dev/null
```

Different distros default to different stacks — Ubuntu Server typically uses Netplan (which itself renders down to either `systemd-networkd` or `NetworkManager`), while many other distros run NetworkManager directly. Persisting an address the wrong way — e.g. hand-editing `ifcfg-eth0` on a NetworkManager-managed host — can be silently overwritten or ignored, so confirming the active stack first avoids wasted work.

## Step 1: Add both addresses live (ephemeral) first

```bash
sudo ip addr add 192.168.10.71/24 dev eth0
sudo ip -6 addr add fd00:10::70/64 dev eth0
```

Check `man ip-address` — the `ip addr add ADDRESS dev DEVICE` form is documented there, including that `ADDRESS` takes CIDR notation directly (no separate netmask argument needed, unlike the old `ifconfig`). Doing this step first gives you immediate, fast feedback that the addresses are valid and don't conflict with anything already assigned, before you touch any persistent config — a live smoke test before committing to a config file.

## Step 2a: Persist with Netplan (if active)

```yaml
# /etc/netplan/50-astro-ats-003-lab-010-secondary.yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.10.70/24
        - 192.168.10.71/24
        - fd00:10::70/64
```

Check `man 5 netplan` and search `/addresses` — the `addresses:` key under an interface takes a YAML list, and it accepts both IPv4 and IPv6 CIDR strings mixed in the same list, which is why the primary, secondary, and IPv6 addresses can all live in one block. Note that Netplan's `addresses:` list is authoritative for that interface — the primary address 192.168.10.70/24 must be listed too, or Netplan may leave it unmanaged/removed depending on how the interface was originally defined; when in doubt, check the existing Netplan file for eth0 and add to it rather than creating a second conflicting file.

```bash
sudo netplan generate
sudo netplan apply
```

`netplan generate` renders the YAML into the backend renderer's native config without applying it — a safe dry-run-adjacent step to catch YAML/schema errors before `apply` actually touches the live network.

## Step 2b: Persist with NetworkManager (if active)

```bash
sudo nmcli con show
sudo nmcli con mod "eth0" +ipv4.addresses 192.168.10.71/24
sudo nmcli con mod "eth0" +ipv6.addresses fd00:10::70/64
sudo nmcli con up "eth0"
```

Check `man nmcli` and search `/ipv4.addresses` — the `+` prefix on `+ipv4.addresses` is documented as an *append* operation (add to the existing list) rather than the plain form, which would overwrite the whole property and drop the primary address. This distinction is the single most common way this step goes wrong.

## Step 3: Add the /etc/hosts entry for forward and reverse resolution

```bash
sudo tee -a /etc/hosts > /dev/null <<'EOF'
192.168.10.71 astro-ats-003-lab-010
EOF
```

Check `man 5 hosts` — the file format is `IP_address canonical_hostname [aliases...]`, one mapping per line. This single line serves both directions: forward lookups of `astro-ats-003-lab-010` return `192.168.10.71`, and reverse lookups of `192.168.10.71` return `astro-ats-003-lab-010`, because glibc's `files` NSS backend scans `/etc/hosts` in both directions from the same table — there's no separate "reverse zone" file needed the way DNS requires a PTR record.

If `astro-ats-003-lab-010` already has an `/etc/hosts` entry for its primary address, decide deliberately whether the new line should replace it or add an alias — duplicate hostname entries resolve to whichever line the NSS backend encounters first when scanning top-to-bottom, which for forward lookups means the first matching line wins.

## Step 4: Confirm hostname vs hosts-file distinction

```bash
hostnamectl status
cat /etc/hostname
```

Check `man hostnamectl` — this only reports and sets the machine's *own* name (static, transient, pretty), which is unrelated to the `/etc/hosts` mapping you just added. The task doesn't ask you to rename the host, only to make the existing hostname resolve to the new address — don't touch `/etc/hostname` or run `hostnamectl set-hostname` here, that would be solving a different problem.

## Step 5: Confirm the resolution order

```bash
grep '^hosts:' /etc/nsswitch.conf
```

Check `man 5 nsswitch.conf`, search `/hosts` — confirm the line reads `hosts: files dns` (or similar, with `files` before `dns`), which guarantees `/etc/hosts` is consulted before any DNS server, so your new line takes effect immediately without depending on DNS at all.

## Verification

```bash
ip -br addr show eth0
```

Expected (both IPv4 addresses and the IPv6 address present):

```text
eth0             UP             192.168.10.70/24 192.168.10.71/24 fd00:10::70/64 fe80::.../64
```

```bash
ip -6 addr show dev eth0
```

```text
inet6 fd00:10::70/64 scope global
inet6 fe80::.../64 scope link
```

```bash
getent hosts astro-ats-003-lab-010
```

```text
192.168.10.71   astro-ats-003-lab-010
```

```bash
getent hosts 192.168.10.71
```

```text
192.168.10.71   astro-ats-003-lab-010
```

```bash
ping -c1 fd00:10::70
```

Should succeed locally, confirming the IPv6 address is actually bound and answering, not just listed.

## Command Summary

```bash
ip -br addr show
systemctl is-active NetworkManager 2>/dev/null
systemctl is-active systemd-networkd 2>/dev/null
ls /etc/netplan/ 2>/dev/null

sudo ip addr add 192.168.10.71/24 dev eth0
sudo ip -6 addr add fd00:10::70/64 dev eth0

# Netplan path:
sudo $EDITOR /etc/netplan/50-astro-ats-003-lab-010-secondary.yaml
sudo netplan generate
sudo netplan apply

# NetworkManager path:
sudo nmcli con mod "eth0" +ipv4.addresses 192.168.10.71/24
sudo nmcli con mod "eth0" +ipv6.addresses fd00:10::70/64
sudo nmcli con up "eth0"

sudo tee -a /etc/hosts > /dev/null <<'EOF'
192.168.10.71 astro-ats-003-lab-010
EOF

grep '^hosts:' /etc/nsswitch.conf

ip -br addr show eth0
getent hosts astro-ats-003-lab-010
getent hosts 192.168.10.71
ping -c1 fd00:10::70
```
