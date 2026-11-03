# Create A Static Profile

Astronaut, now you write your first entry in the flight manual. In this part you build a connection profile with a static address, switch it on, and then open the file NetworkManager saved on disk.

## Creating a static profile

`nmcli connection add` creates a profile. It needs a few essentials, and one of them is easy to mix up with another.

### The essentials

A profile needs:

- a `type` (here `ethernet`),
- a `con-name`, the profile's own name. This is **not** the interface name,
- the `ifname` it binds to, the interface,
- the addressing.

For a static address, set `ipv4.method manual` and give `ipv4.addresses`. A static address is a call sign painted on the hull by the crew, instead of one handed out by the harbour master (DHCP, the Dynamic Host Configuration Protocol). Here is a full example with a gateway and a DNS (Domain Name System, the galaxy-wide directory of call signs) server:

<!-- astrona:playground:renew -->

```sh
sudo nmcli connection add type ethernet con-name lab-static ifname enp2s0 \
    ipv4.method manual \
    ipv4.addresses 192.168.120.50/24 \
    ipv4.gateway 192.168.120.1 \
    ipv4.dns 192.168.120.1
```

The shorthand `ip4 192.168.120.50/24 gw4 192.168.120.1` on the `add` line does the same, and sets `manual` for you. Creating a profile does not apply it. `nmcli connection up` does that.

### Build the profile and activate it

Use your spare interface name in place of `enp2s0`. This shorter version sets only the address, then activates the profile and checks it:

```sh
sudo nmcli connection add type ethernet con-name lab-static ifname enp2s0 \
    ipv4.method manual ipv4.addresses 192.168.120.50/24
sudo nmcli connection up lab-static
nmcli -f ipv4 connection show lab-static
ip -brief addr show enp2s0
```

Expect the address in the profile and on the interface:

```text
ipv4.method:       manual
ipv4.addresses:    192.168.120.50/24
```

```text
enp2s0   UP   192.168.120.50/24
```

`nmcli device status` now shows `enp2s0` as `connected` with `lab-static`. The address is exactly what `ip addr add` would have set. The difference is that NetworkManager wrote this one to disk, so it comes back after a reboot.

## Where the profile is stored

NetworkManager writes each profile to a **keyfile** under `/etc/NetworkManager/system-connections/`, named `<con-name>.nmconnection`. Knowing where it lives lets you read exactly what NetworkManager will apply.

### The keyfile format

The keyfile is in INI format, owned by root, with mode `600`. Only root may read it, because profiles can hold secrets such as Wi-Fi passwords and VPN (virtual private network) keys.

### Read the on-disk form

Print the keyfile of your new profile:

```sh
sudo cat /etc/NetworkManager/system-connections/lab-static.nmconnection
```

Expect the settings you passed to `nmcli`, as INI sections:

```text
[connection]
id=lab-static
type=ethernet
interface-name=enp2s0

[ipv4]
method=manual
address1=192.168.120.50/24
```

Everything `nmcli` did is here. You can edit this file directly. After a hand edit, run `sudo nmcli connection reload` so NetworkManager reads it again. Without the reload it keeps using its cached copy and may overwrite your edit.

## Common pitfalls

> [!WARNING]
> - **Confusing `con-name` with `ifname`.** The profile name and the interface name are independent. `nmcli connection up` takes the profile name; `nmcli device connect` takes the interface.
> - **Expecting `add` to apply the profile.** `nmcli connection add` only saves it. Run `nmcli connection up` to make it live.
> - **Editing the keyfile without `nmcli connection reload`.** NetworkManager keeps its cached copy and can overwrite your hand edit on the next `up`.
> - **Deleting the active profile on a remote machine's only interface.** `nmcli connection delete` drops the connection at once. It is safe here on the spare interface, but on a production server it locks you out.
