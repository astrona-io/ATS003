# Solution Walkthrough

You will add a second IPv4 address, an IPv6 address, and two `/etc/hosts`
entries to the primary interface, then write the addresses into a config
file so they come back after a reboot.

Everything on the VM runs on `terminal`. None of these steps touch the
management address or the default route, so your session stays connected the
whole time.

Three things to remember, one per task:

| Goal | Where it lives | Command / file |
| --- | --- | --- |
| Address **now** (temporary) | running kernel | `sudo ip addr add …` |
| Address **after reboot** (permanent) | `/etc/netplan/*.yaml` | edit a file, then `sudo netplan apply` |
| A **name** for an address | `/etc/hosts` | add one line |

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`, not the shell inside the VM. The command is:

```bash
astrona test -c labs/section-010/capstone/lab-01
```

It runs all six checks against the live VM and prints one line each:

```text
PASS  secondary-ipv4
FAIL  ipv6-address
FAIL  ipv6-reachable
FAIL  hosts-forward
FAIL  hosts-reverse
FAIL  persistence
```

Run it now, before doing anything, to see everything fail. Then run it again
after **every** step below — each step turns one or two more lines green, so
you always know exactly where you are. Keep the host terminal open next to
the VM terminal.

---

## Step 1: Find the primary interface

*(No check flips yet — this step just gathers information.)*

On the VM, show the routing table:

```bash
ip route
```

Read the first line. It looks like this:

```text
default via 10.0.0.1 dev enp0s1 proto dhcp src 10.0.0.20 metric 100
```

The word after `dev` is your primary interface. In this example it is
**`enp0s1`**. Yours may be `ens3`, `eth0`, or similar — wherever a command
below says `enp0s1`, type your own name instead.

Now look at what the interface already has:

```bash
ip addr show enp0s1
```

You will see one IPv4 address (the DHCP management address, for example
`10.0.0.20/24`). That address and the default route must stay. You are only
**adding** next to them.

---

## Step 2: Add both addresses for right now

`ip addr add` puts an address on an interface immediately. It adds to what
is already there — it does not replace anything.

Add the IPv4 address:

```bash
sudo ip addr add 192.168.10.71/24 dev enp0s1
```

Add the IPv6 address (note `-6`):

```bash
sudo ip -6 addr add fd00:10::70/64 dev enp0s1
```

Check they are both on the interface now:

```bash
ip addr show enp0s1
```

You should see the original address, plus `192.168.10.71/24`, plus
`fd00:10::70/64`.

**Run the check** on the host terminal:

```bash
astrona test -c labs/section-010/capstone/lab-01
```

`secondary-ipv4` now passes. `ipv6-address` and `ipv6-reachable` may pass
already, or still fail for a few seconds — that is Step 3.

---

## Step 3: Wait for IPv6, then test it

When you add an IPv6 address, Linux spends a second or two checking that no
other machine already uses it. During that check the address is marked
`tentative`, and the `ipv6-address` check will not accept it while it says
that.

On the VM, look at the IPv6 address:

```bash
ip -6 addr show enp0s1
```

Find the `fd00:10::70/64` line. If it contains the word `tentative`, wait a
few seconds and run the command again. When `tentative` is gone, it is
ready.

Test that the address answers:

```bash
ping -6 -c 3 fd00:10::70
```

You want `0% packet loss`.

**Run the check** again on the host terminal. Now green:

```text
PASS  secondary-ipv4
PASS  ipv6-address
PASS  ipv6-reachable
FAIL  hosts-forward
FAIL  hosts-reverse
FAIL  persistence
```

---

## Step 4: Make the addresses survive a reboot

The addresses from Step 2 disappear if the machine reboots. To keep them,
write them into a Netplan config file.

Do not edit the file that is already in `/etc/netplan/` (the one from
cloud-init). Make a new file next to it. Netplan reads every `.yaml` file in
that folder and combines them.

On the VM, open a new file with an editor:

```bash
sudo nano /etc/netplan/99-lab-secondary.yaml
```

Type this into it. Use spaces, not tabs, and keep the indentation exactly as
shown. Replace `enp0s1` with your interface name:

```yaml
network:
  version: 2
  ethernets:
    enp0s1:
      dhcp4: true
      addresses:
        - 192.168.10.71/24
        - "fd00:10::70/64"
```

What each part does:

- `enp0s1:` — the interface these settings apply to. Must match your name.
- `dhcp4: true` — keep asking DHCP for the management address. Leave this
  in, or applying the file will drop your session.
- `addresses:` — the two static addresses to add. The IPv6 one is in quotes
  because YAML dislikes the bare colons.

Save and exit (`nano`: `Ctrl+O`, `Enter`, then `Ctrl+X`).

Netplan warns if the file can be read by everyone. Fix the permissions:

```bash
sudo chmod 600 /etc/netplan/99-lab-secondary.yaml
```

Apply the file:

```bash
sudo netplan apply
```

Check the addresses are still there:

```bash
ip addr show enp0s1
```

**Run the check** again on the host terminal — `persistence` now passes.

> **If this machine uses NetworkManager instead of Netplan:** add the same
> two addresses to the connection profile. First list the connections with
> `nmcli connection show` and note the name for your interface (often
> `netplan-enp0s1` or `Wired connection 1`). Then, using that name:
>
> ```bash
> sudo nmcli connection modify "Wired connection 1" +ipv4.addresses 192.168.10.71/24
> sudo nmcli connection modify "Wired connection 1" +ipv6.addresses fd00:10::70/64
> sudo nmcli connection up "Wired connection 1"
> ```
>
> The `persistence` check looks in both places, so either method passes. Use
> one, not both.

---

## Step 5: Give the address a name in /etc/hosts

`/etc/hosts` is a plain list of `IP  name` lines. One line gives you both
forward lookups (name to IP) and reverse lookups (IP to name).

On the VM, open the file:

```bash
sudo nano /etc/hosts
```

Add this line at the end (leave the existing lines alone — do not attach the
name to the `127.0.1.1` line):

```text
192.168.10.71   app-srv1
```

Save and exit.

Check both directions:

```bash
getent hosts app-srv1
getent hosts 192.168.10.71
```

The first should print `192.168.10.71`. The second should print a line that
includes `app-srv1`.

**Run the check** again on the host terminal — `hosts-forward` and
`hosts-reverse` now pass. All six green.

---

## Step 6: Submit

When `astrona test` shows all six `PASS`:

```text
PASS  secondary-ipv4
PASS  ipv6-address
PASS  ipv6-reachable
PASS  hosts-forward
PASS  hosts-reverse
PASS  persistence
```

Submit from the host terminal:

```bash
astrona submit -c labs/section-010/capstone/lab-01
```

---

## If a check stays red

- **The management address vanished / session froze.** Your Netplan file is
  missing `dhcp4: true`, or the interface name in it is wrong. Fix the file
  and run `sudo netplan apply` again; the DHCP address usually comes back on
  its own.
- **`ipv6-address` fails.** Re-check `ip -6 addr show enp0s1`. If the
  `fd00:10::70/64` line still says `tentative`, wait and look again before
  the next `astrona test`.
- **`persistence` fails but the addresses show in `ip addr`.** They are only
  the temporary ones from Step 2. Do Step 4 — put them in the Netplan file
  and apply it.
- **`hosts-forward` returns nothing.** The name is on the wrong line in
  `/etc/hosts`. It needs its own line: `192.168.10.71   app-srv1`.
