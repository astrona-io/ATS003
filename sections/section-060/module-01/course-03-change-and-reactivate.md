# Change, Reactivate And Keep A Profile

Astronaut, a profile is a living set of orders. In this part you change one, learn why the change waits until you reactivate it, see what happens when you ask for DHCP (Dynamic Host Configuration Protocol, the harbour master who hands out call signs) where nobody hands out addresses, and prove the profile survives a reboot.

The commands below need a static profile called `lab-static` with the address `192.168.120.50/24`, active on the spare interface. If you do not have it yet, create it with `sudo nmcli connection add type ethernet con-name lab-static ifname enp2s0 ipv4.method manual ipv4.addresses 192.168.120.50/24` and `sudo nmcli connection up lab-static`, using your own interface name.

## A change is not live until you reactivate

`nmcli connection modify` edits the saved profile. It does **not** change the running interface. This is the most common reason for "my nmcli change did nothing".

### How `modify` works

The new settings take effect only when the profile is brought up again, with `nmcli connection up <name>` or `nmcli device reapply <dev>`.

`modify` also has `+` and `-` prefixes. `+ipv4.addresses` adds another address, `-ipv4.dns` removes one, and plain `ipv4.addresses` replaces the whole list.

### Add a second address and watch it wait

<!-- astrona:playground:renew -->

Add a second address to the `lab-static` profile, then look at the interface:

```sh
sudo nmcli connection modify lab-static +ipv4.addresses 192.168.120.51/24
ip -brief addr show enp2s0
```

The interface still shows only the first address:

```text
enp2s0   UP   192.168.120.50/24
```

Now reactivate the profile and look again:

```sh
sudo nmcli connection up lab-static
ip -brief addr show enp2s0
```

```text
enp2s0   UP   192.168.120.50/24 192.168.120.51/24
```

The profile held the change from the moment you ran `modify`. The interface only caught up on `up`.

## `manual` versus `auto`

`ipv4.method` decides where the address comes from. `manual` is the static case, as in `lab-static`. `auto` runs a DHCP client on the interface, which asks the harbour master for a call sign.

### Switch to DHCP where there is no DHCP server

There is no DHCP server on this segment, so `auto` shows you what "no lease" looks like:

```sh
sudo nmcli connection modify lab-static ipv4.method auto
sudo nmcli connection up lab-static ; echo "exit: $?"
ip -brief addr show enp2s0
```

Activation stalls and then fails, and the interface ends up with no routable address:

```text
Error: Connection activation failed: IP configuration could not be reserved (no available address, timeout, etc.)
exit: 4
```

With `method auto` and nothing answering DHCP, NetworkManager cannot bring the profile up. Set it back with `sudo nmcli connection modify lab-static ipv4.method manual` and `sudo nmcli connection up lab-static`.

## Autoconnect

`connection.autoconnect` (default `yes`) decides whether NetworkManager brings a profile up on its own. It does so at boot, when the profile's device appears, and after the profile is deactivated. That last case surprises people: with autoconnect on, `nmcli connection down` is often undone within a second.

### Down with autoconnect on, then off

Take the profile down and check what is active two seconds later:

```sh
sudo nmcli connection down lab-static
sleep 2
nmcli -f NAME,DEVICE,STATE connection show --active
```

With autoconnect at its default, `lab-static` is likely **back**:

```text
NAME        DEVICE  STATE
lab-static  enp2s0  activated
```

Now turn autoconnect off and try again:

```sh
sudo nmcli connection modify lab-static connection.autoconnect no
sudo nmcli connection down lab-static
sleep 2
nmcli -f NAME,DEVICE,STATE connection show --active
```

This time it stays down. `nmcli device disconnect enp2s0` is the stronger form: it also blocks autoconnect on that device until you connect it again.

## Persistence: surviving a reboot

The whole point of a profile is that it outlives a reboot. With `connection.autoconnect yes`, NetworkManager applies the profile again at boot.

### Reboot and check

Set autoconnect back on first, then restart the virtual machine. This drops your SSH (Secure Shell, a sealed communications channel between two ships) session for about a minute; reconnect with `astrona ssh networkmanager-nmcli-playground`:

```sh
sudo nmcli connection modify lab-static connection.autoconnect yes
sudo reboot
```

After reconnecting, list the profiles and the address:

```sh
nmcli -f NAME,DEVICE,STATE connection show
ip -brief addr show enp2s0
```

Look for `lab-static` still listed and `enp2s0` carrying its address again. The keyfile survived and NetworkManager applied it once more. An address added with `ip addr add` would be gone.

## Managed versus unmanaged

NetworkManager only configures devices it **manages**. Knowing why a device is `unmanaged` tells you who else owns it.

### Who owns an interface

A device is left `unmanaged` when another tool already owns it (Netplan, systemd-networkd, ifupdown), or when a rule says so. In this playground, `/etc/NetworkManager/conf.d/10-managed.conf` limits NetworkManager to the spare interface:

```ini
[keyfile]
unmanaged-devices=*,except:interface-name:enp2s0
```

On a real host, the mirror-image mistake is having **two** managers active on one interface, for example NetworkManager and systemd-networkd both trying to set it. The interface flaps, and addresses appear and vanish. If `nmcli device status` shows `unmanaged` for an interface you expected NetworkManager to control, something else has claimed it.

## Common pitfalls

> [!WARNING]
> - **`modify` without `up`.** `nmcli connection modify` changes the saved profile only. The interface does not change until `nmcli connection up` (or `nmcli device reapply`).
> - **`ipv4.addresses` without `ipv4.method manual`.** Setting an address with `modify` does not switch the method off `auto`. The `ip4` shorthand on `add` does; a later `modify ipv4.addresses` does not.
> - **Autoconnect undoing a `down`.** With `connection.autoconnect yes`, a deactivated profile often comes straight back. Set it to `no`, or use `nmcli device disconnect`.
> - **Two managers on one interface.** Check `nmcli device status` for `unmanaged` before you blame NetworkManager.

## Your mission: Private And Public Address Audit Lab

You can now read which address each interface carries and tell a runtime address from a saved one. The graded mission does not ask you to build a profile: it asks for an address audit. You find the private address the host's own interface carries and the public address the internet sees after NAT (network address translation, the relay station that swaps your call sign for its own), and write each one to a file.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop networkmanager-nmcli-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-01/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-060/module-01/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-061
astrona start networkmanager-nmcli-playground
```
