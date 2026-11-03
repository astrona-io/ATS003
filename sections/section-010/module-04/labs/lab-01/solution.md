# Solution Walkthrough

You will add a second IPv4 address and an IPv6 address to the primary interface, write both into a configuration file so they come back after a reboot, and give the new IPv4 address a name in `/etc/hosts`.

Everything on the lab machine (the virtual machine, or VM) runs in its `terminal`. None of these steps touch the management address or the default route, so your session stays connected the whole time.

Three things to remember, one per task:

| Goal | Where it lives | Command / file |
| --- | --- | --- |
| Address **now** (temporary) | running kernel | `sudo ip addr add …` |
| Address **after reboot** (permanent) | `/etc/netplan/*.yaml` | write a file, then `sudo netplan apply` |
| A **name** for an address | `/etc/hosts` | add one line |

## The feedback loop

Grading runs from your **own terminal**: the shell where you typed `astrona run`, not the shell inside the VM. The command is:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-010/module-04/labs/lab-01
```

It runs six checks against the live VM and prints one line for each. A run part of the way through looks like this:

```text
PASS  secondary-ipv4
FAIL  ipv6-address
FAIL  ipv6-reachable
FAIL  hosts-forward
FAIL  hosts-reverse
FAIL  persistence
```

Run it once before you change anything, and most lines fail. Then run it again after **every** step below. Each step turns one or two more lines green, so you always know where you are. Keep your own terminal open next to the VM terminal.

---

## Step 1: Find the primary interface

*(No check changes yet. This step only gathers information.)*

On the VM, show the routing table:

```bash
ip route
```

Read the first line. It looks like this:

```text
default via 10.0.0.1 dev enp0s1 proto dhcp src 10.0.0.20 metric 100
```

The word after `dev` is your primary interface. In this example it is **`enp0s1`**. Yours may be `ens3`, `eth0` or similar. Wherever a command below says `enp0s1`, type your own name instead.

Now look at what the interface already has:

```bash
ip addr show enp0s1
```

You see one IPv4 address: the management address from DHCP, for example `10.0.0.20/24`. That address and the default route must stay. You are only **adding** next to them.

---

## Step 2: Add both addresses for right now

`ip addr add` puts an address on an interface at once. It adds to what is already there; it does not replace anything.

Add the IPv4 address:

```bash
sudo ip addr add 192.168.10.71/24 dev enp0s1
```

Add the IPv6 address (note the `-6`):

```bash
sudo ip -6 addr add fd00:10::70/64 dev enp0s1
```

Check that both are on the interface now:

```bash
ip addr show enp0s1
```

You should see the original address, plus `192.168.10.71/24`, plus `fd00:10::70/64`.

**Run the check** in your own terminal:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-010/module-04/labs/lab-01
```

`secondary-ipv4` now passes. `ipv6-address` and `ipv6-reachable` may pass already, or still fail for a few seconds. Step 3 explains why.

---

## Step 3: Wait for IPv6, then test it

When you add an IPv6 address, the kernel spends a second or two checking that no other machine on the segment already uses it. This is called duplicate address detection. During that check the address is marked `tentative`, and the `ipv6-address` check does not accept it.

On the VM, look at the IPv6 address:

```bash
ip -6 addr show enp0s1
```

Find the `fd00:10::70/64` line. If it contains the word `tentative`, wait a few seconds and run the command again. When `tentative` is gone, the address is ready.

Test that the address answers:

```bash
ping -6 -c 3 fd00:10::70
```

You want `0% packet loss`.

**Run the check** again in your own terminal. Now three lines are green:

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

The addresses from Step 2 disappear if the machine reboots. To keep them, write them into a Netplan configuration file: the flight manual the machine reads at every boot.

Do not edit the file that is already in `/etc/netplan/` (cloud-init wrote it for the management interface). Make a new file next to it. Netplan reads every `.yaml` file in that folder and combines them.

Save this as `/etc/netplan/99-lab-secondary.yaml` (for example with `sudo nano /etc/netplan/99-lab-secondary.yaml`). Use spaces, not tabs, keep the indentation exactly as shown, and replace `enp0s1` with your interface name:

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

- `enp0s1:` is the interface these settings apply to. It must match your interface name.
- `dhcp4: true` keeps asking DHCP for the management address. Leave it in, or applying the file drops your session.
- `addresses:` lists the two static addresses to add. The IPv6 address is in quotes because YAML does not like the bare colons.

In `nano`, save with `Ctrl+O` and `Enter`, then leave with `Ctrl+X`.

Netplan warns if everyone can read the file. Fix the permissions:

```bash
sudo chmod 600 /etc/netplan/99-lab-secondary.yaml
```

Apply it:

```bash
sudo netplan apply
```

Then check the result:

```bash
ip addr show enp0s1
```

Both addresses are still there. **Run the check** again in your own terminal: `persistence` now passes.

If this machine uses NetworkManager instead of Netplan, add the same two addresses to the connection profile instead. First list the connections with `nmcli connection show`, and note the name for your interface (often `netplan-enp0s1` or `Wired connection 1`). Then, using that name:

```bash
sudo nmcli connection modify "Wired connection 1" +ipv4.addresses 192.168.10.71/24
sudo nmcli connection modify "Wired connection 1" +ipv6.addresses fd00:10::70/64
sudo nmcli connection up "Wired connection 1"
```

The `persistence` check looks in both places, so either method passes. Use one, not both.

---

## Step 5: Give the address a name in /etc/hosts

`/etc/hosts` is the ship's pocket address book: a plain list of `IP  name` lines. One line gives you both forward lookups (name to address) and reverse lookups (address to name).

On the VM, open the file:

```bash
sudo nano /etc/hosts
```

Add this line at the end. Leave the existing lines alone, and do not attach the name to the `127.0.1.1` line:

```text
192.168.10.71   app-srv1
```

Save and leave the editor.

Check both directions:

```bash
getent hosts app-srv1
getent hosts 192.168.10.71
```

The first prints `192.168.10.71`. The second prints a line that includes `app-srv1`.

**Run the check** again in your own terminal: `hosts-forward` and `hosts-reverse` now pass. All six are green.

---

## Step 6: Submit

When `astrona submit` shows all six `PASS`:

```text
PASS  secondary-ipv4
PASS  ipv6-address
PASS  ipv6-reachable
PASS  hosts-forward
PASS  hosts-reverse
PASS  persistence
```

Submit from your own terminal:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-010/module-04/labs/lab-01
```

---

## If a check stays red

- **The management address vanished or the session froze.** Your Netplan file is missing `dhcp4: true`, or the interface name in it is wrong. Fix the file and run `sudo netplan apply` again. The DHCP address usually comes back on its own.
- **`ipv6-address` fails.** Look again with `ip -6 addr show enp0s1`. If the `fd00:10::70/64` line still says `tentative`, wait and look again before the next `astrona submit`.
- **`persistence` fails but the addresses show in `ip addr`.** They are only the temporary ones from Step 2. Do Step 4: put them in the Netplan file and apply it.
- **`hosts-forward` returns nothing.** The name is on the wrong line in `/etc/hosts`. It needs its own line: `192.168.10.71   app-srv1`.
