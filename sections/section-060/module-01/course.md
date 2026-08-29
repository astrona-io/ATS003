# Persistent Network Managers

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-060/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-01/playground
> astrona destroy networkmanager-nmcli-playground
> ```

Addresses and routes set with `ip addr add` or `ip route add` live only in the
running kernel — a reboot wipes them. To make network configuration **stick**,
it has to be written to disk by a system that reapplies it on every boot. The
common ones on Linux are **NetworkManager**, **systemd-networkd**, **netplan**
(an Ubuntu front end that renders to one of the other two), and the older
**ifupdown**. Exactly one should own any given interface.

This module is about **NetworkManager**, driven from the command line with
**`nmcli`**. Its core idea is a separation:

- A **device** is an interface the kernel has — `enp1s0`, `wlan0`, `bond0`.
  NetworkManager does not store settings on the device.
- A **connection** (or connection *profile*) is a named bundle of settings —
  addressing, DNS, routes, which device it binds to, whether to activate
  automatically. Profiles are what you create, edit, and save.

One device can have several profiles on file — a static one for the office, a
DHCP one for elsewhere — with one **active** at a time. Bringing a profile "up"
applies its settings to its device.

## Learning objectives

After this module you can:

- Explain why `ip addr` / `ip route` changes do not persist, and which system
  makes them persistent.
- Describe NetworkManager's split between devices and connection profiles, and
  read `nmcli device status` and `nmcli connection show`.
- Create a static connection profile with `nmcli connection add` and activate it
  with `nmcli connection up`.
- Modify a profile's addressing, DNS, and autoconnect with `nmcli connection
  modify`, and explain why a reactivation is needed.
- Locate a profile's keyfile under `/etc/NetworkManager/system-connections/` and
  reload it after a hand edit.
- Explain `managed` versus `unmanaged` devices and why only one tool should own
  an interface.

## Before you start

This module builds on the interfaces, addressing, and DNS material — interface
names, CIDR notation (`192.168.120.50/24`), default gateway, and DNS resolver
are used without re-explaining. You should be able to open a shell, use `sudo`,
and read an INI-style file.

The playground is a single VM (`astrona ssh networkmanager-nmcli-playground`)
where NetworkManager is installed but **restricted to one spare NIC** on the
isolated `192.168.120.0/24` segment. That segment has **no DHCP server and no
router**. The interface carrying your SSH session is left `unmanaged` by
NetworkManager, so every `nmcli` command below is safe. The spare NIC has **no
profile yet** — find its name with `ip -br link` or `nmcli device status` (it is
the one shown `disconnected`, not `unmanaged`). `sudo` needs no password.

## Devices and connections

`nmcli` is organised by object: `nmcli device …` inspects interfaces, `nmcli
connection …` manages profiles. The first thing to look at is which devices
NetworkManager can see and what state they are in — `connected`, `disconnected`
(managed but no active profile), `unavailable`, or `unmanaged`.

> [!TIP]
> **Try it — what NetworkManager is managing**
>
> ```sh
> nmcli device status
> nmcli connection show
> ```
>
> Expect the spare NIC managed with no profile, and the SSH NIC untouched:
>
> ```text
> DEVICE  TYPE      STATE         CONNECTION
> enp1s0  ethernet  unmanaged     --
> enp2s0  ethernet  disconnected  --
> lo      loopback  unmanaged     --
>
> NAME  UUID  TYPE  DEVICE
> ```
>
> `enp1s0` (your SSH interface) is `unmanaged` — NetworkManager will not touch
> it. `enp2s0` is `disconnected`: managed, but with no connection profile, so it
> has no address. `nmcli connection show` is empty because nothing has been
> created. Interface names vary — use yours below.

## Creating a static profile

`nmcli connection add` creates a profile. The essentials: a `type`, a
`con-name` (the profile's name — *not* the interface name), the `ifname` it
binds to, and the addressing. For a static address, set `ipv4.method manual`
and give `ipv4.addresses`:

```sh
sudo nmcli connection add type ethernet con-name lab-static ifname enp2s0 \
    ipv4.method manual \
    ipv4.addresses 192.168.120.50/24 \
    ipv4.gateway 192.168.120.1 \
    ipv4.dns 192.168.120.1
```

(The shorthand `ip4 192.168.120.50/24 gw4 192.168.120.1` on the `add` line does
the same and sets `manual` for you.) Creating a profile does not apply it —
`nmcli connection up` does.

> [!TIP]
> **Try it — build the profile and activate it**
>
> Use your spare interface name in place of `enp2s0`:
>
> ```sh
> sudo nmcli connection add type ethernet con-name lab-static ifname enp2s0 \
>     ipv4.method manual ipv4.addresses 192.168.120.50/24
> sudo nmcli connection up lab-static
> nmcli -f ipv4 connection show lab-static
> ip -brief addr show enp2s0
> ```
>
> Expect the address on the interface and the profile now active:
>
> ```text
> ipv4.method:       manual
> ipv4.addresses:    192.168.120.50/24
> ```
>
> ```text
> enp2s0   UP   192.168.120.50/24
> ```
>
> `nmcli device status` now shows `enp2s0` as `connected` using `lab-static`.
> The address is exactly what `ip addr add` would have set — but this one is on
> disk and will come back after a reboot.

## Where the profile is stored

NetworkManager writes each profile to a **keyfile** under
`/etc/NetworkManager/system-connections/`, named `<con-name>.nmconnection`. It
is INI format, owned by root, mode `600` — because profiles can hold secrets
(Wi-Fi passwords, VPN keys).

> [!TIP]
> **Try it — read the on-disk form**
>
> ```sh
> sudo cat /etc/NetworkManager/system-connections/lab-static.nmconnection
> ```
>
> Expect the settings you passed to `nmcli`, as INI sections:
>
> ```text
> [connection]
> id=lab-static
> type=ethernet
> interface-name=enp2s0
>
> [ipv4]
> method=manual
> address1=192.168.120.50/24
> ```
>
> Everything `nmcli` did is here. You can edit this file directly, but then you
> must run `sudo nmcli connection reload` so NetworkManager re-reads it —
> otherwise it keeps using its cached copy and may overwrite your edit.

## A change is not live until you reactivate

`nmcli connection modify` edits the saved profile. It does **not** change the
running interface. The new settings take effect only when the profile is
brought up again — `nmcli connection up <name>`, or `nmcli device reapply
<dev>`.

`modify` also has `+` and `-` prefixes: `+ipv4.addresses` adds another address,
`-ipv4.dns` removes one, plain `ipv4.addresses` replaces the whole list.

> [!TIP]
> **Try it — add a second address, see it stay inert, then apply it**
>
> ```sh
> sudo nmcli connection modify lab-static +ipv4.addresses 192.168.120.51/24
> ip -brief addr show enp2s0
> ```
>
> The interface still shows only the first address:
>
> ```text
> enp2s0   UP   192.168.120.50/24
> ```
>
> Now reactivate and look again:
>
> ```sh
> sudo nmcli connection up lab-static
> ip -brief addr show enp2s0
> ```
>
> ```text
> enp2s0   UP   192.168.120.50/24 192.168.120.51/24
> ```
>
> The profile held the change from the moment you ran `modify`; the interface
> only caught up on `up`. Editing and forgetting to reactivate is the most
> common "my nmcli change did nothing".

## `manual` versus `auto`

`ipv4.method` decides where the address comes from. `manual` is the static case
above. `auto` runs a DHCP client on the interface. There is no DHCP server on
this segment, so `auto` is a good way to see what "no lease" looks like.

> [!TIP]
> **Try it — switch to DHCP where there is no DHCP**
>
> ```sh
> sudo nmcli connection modify lab-static ipv4.method auto
> sudo nmcli connection up lab-static ; echo "exit: $?"
> ip -brief addr show enp2s0
> ```
>
> Activation stalls and then fails, and the interface ends up with no routable
> address:
>
> ```text
> Error: Connection activation failed: IP configuration could not be reserved (no available address, timeout, etc.)
> exit: 4
> ```
>
> With `method auto` and nothing answering DHCP, NetworkManager cannot bring the
> profile up. Set it back with `sudo nmcli connection modify lab-static
> ipv4.method manual` and `sudo nmcli connection up lab-static`.

## Autoconnect

`connection.autoconnect` (default `yes`) decides whether NetworkManager brings a
profile up on its own — at boot, or when its device appears, or after the
profile is deactivated. That last case surprises people: with autoconnect on,
`nmcli connection down` is often undone within a second.

> [!TIP]
> **Try it — down with autoconnect on, then off**
>
> ```sh
> sudo nmcli connection down lab-static
> sleep 2
> nmcli -f NAME,DEVICE,STATE connection show --active
> ```
>
> With autoconnect at its default, `lab-static` is likely **back**:
>
> ```text
> NAME        DEVICE  STATE
> lab-static  enp2s0  activated
> ```
>
> Now turn autoconnect off and try again:
>
> ```sh
> sudo nmcli connection modify lab-static connection.autoconnect no
> sudo nmcli connection down lab-static
> sleep 2
> nmcli -f NAME,DEVICE,STATE connection show --active
> ```
>
> This time it stays down. `nmcli device disconnect enp2s0` is the stronger
> form — it also blocks autoconnect on that device until you reconnect it.

## Persistence

The whole point of a profile is that it outlives a reboot. With
`connection.autoconnect yes`, the profile is reapplied automatically at boot.

> [!TIP]
> **Try it — reboot and check**
>
> Set autoconnect back on first, then restart the VM (this drops your SSH
> session for about a minute; reconnect with `astrona ssh
> networkmanager-nmcli-playground`):
>
> ```sh
> sudo nmcli connection modify lab-static connection.autoconnect yes
> sudo reboot
> ```
>
> After reconnecting:
>
> ```sh
> nmcli -f NAME,DEVICE,STATE connection show
> ip -brief addr show enp2s0
> ```
>
> Expect `lab-static` still listed and `enp2s0` addressed again — the keyfile
> survived and NetworkManager reapplied it. Contrast with an `ip addr add`,
> which would be gone.

## Managed versus unmanaged

NetworkManager only configures devices it **manages**. A device is left
`unmanaged` when another tool already owns it (netplan, systemd-networkd,
ifupdown), or when a rule says so. In this playground,
`/etc/NetworkManager/conf.d/10-managed.conf` restricts NetworkManager to the
spare NIC:

```ini
[keyfile]
unmanaged-devices=*,except:interface-name:enp2s0
```

On a real host, the mirror-image mistake is having **two** managers active on
one interface — NetworkManager and systemd-networkd both trying to set it. The
interface flaps, addresses appear and vanish. `nmcli device status` showing
`unmanaged` for an interface you expected NM to control is the tell that
something else has claimed it.

## Where this fits

This is the persistent layer beneath everything from the interfaces, addressing,
routing, and DNS modules — the same `inet` addresses, prefixes, gateways, and
resolvers, now written to a keyfile instead of typed into `ip`. `nmcli` is one
way in; `nmtui` (a text UI), editing `.nmconnection` files plus `nmcli
connection reload`, and configuration-management tools (Ansible's `nmcli`
module) are others, all driving the same profiles. On Ubuntu, netplan may be the
front end and can be told to use NetworkManager as its renderer; on a
NetworkManager-managed host, `nmcli` writes DNS into `/etc/resolv.conf` or hands
it to `systemd-resolved`, tying back to the local-resolution module.

> [!WARNING]
> **Common pitfalls**
>
> - **`modify` without `up`.** `nmcli connection modify` changes the saved
>   profile only. The interface does not change until `nmcli connection up`
>   (or `nmcli device reapply`).
> - **Two managers on one interface.** NetworkManager and systemd-networkd /
>   netplan / ifupdown all configuring the same NIC causes flapping. One owner
>   per interface; check `nmcli device status` for `unmanaged`.
> - **`ipv4.addresses` without `ipv4.method manual`.** Setting an address via
>   `modify` does not switch the method off `auto`. The `ip4` shorthand on `add`
>   does; a later `modify ipv4.addresses` does not.
> - **Editing the keyfile without `nmcli connection reload`.** NetworkManager
>   keeps its cached copy and can overwrite your hand edit on the next `up`.
> - **Confusing `con-name` with `ifname`.** The profile name and the interface
>   name are independent. `nmcli connection up` takes the profile name;
>   `nmcli device connect` takes the interface.
> - **Deleting the active profile on a remote box's only NIC.** `nmcli
>   connection delete` drops the connection immediately. Safe here on the spare
>   NIC; a lockout on a production host.
> - **Autoconnect undoing a `down`.** With `connection.autoconnect yes`, a
>   deactivated profile often comes straight back. Set it to `no`, or use
>   `nmcli device disconnect`.
