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

`connection.autoconnect yes` permits NetworkManager to activate an eligible saved profile when its device becomes available, including after boot. It does not replace an already active profile.

A manual `nmcli connection down lab-static` blocks that profile from autoconnecting again until it is explicitly activated or the relevant state resets. Do not use a quick down-and-wait check as proof of reboot behavior. Instead, inspect the setting, explicitly activate the profile, and check again after a real reboot:

```bash
nmcli -g connection.autoconnect connection show lab-static
sudo nmcli connection modify lab-static connection.autoconnect yes
sudo nmcli connection up lab-static
```

For an isolated practice interface, `ipv4.never-default yes` prevents that profile from supplying the default route. A `dummy` profile creates a virtual interface for local configuration practice; it does not provide an external network connection. The graded exercise supplies such a device as `nm0`.

See the [NetworkManager connection properties](https://networkmanager.dev/docs/api/latest/nm-settings-nmcli.html).

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
> - **Treating a manual disconnect as a reboot test.** Inspect the saved autoconnect setting and test a real reboot.
> - **Two managers on one interface.** Check `nmcli device status` for `unmanaged` before you blame NetworkManager.

## Practice: Repair a persistent NetworkManager profile

Diagnose the saved and active settings of lab-static. Correct its address and enable autoconnect. Reactivate the profile and verify it after reboot. This lab starts independently; changes in the playground do not carry over.

Pause the playground first:

```bash
astrona stop networkmanager-nmcli-playground
```

Read the [task](labs/lab-01/question.md), then start the lab:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-01/labs/lab-01
```

Use the inspection commands while working. Submit once all tasks are complete; submission ends the environment.

Resume the playground afterwards:

```bash
astrona start networkmanager-nmcli-playground
```
