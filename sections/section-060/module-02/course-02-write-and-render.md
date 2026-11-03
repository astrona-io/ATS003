# Write And Render A Netplan File

Astronaut, time to write your own page in the flight manual. In this part you describe the spare interface in YAML, watch the parser refuse a tab, and read the file Netplan writes for the renderer, all without changing the running network.

## Writing an interface block

A static interface needs `dhcp4: false`, an `addresses` list where each entry **includes** its prefix, and usually `routes` and `nameservers`. The layout matters as much as the values.

### Spaces, two at a time

Indentation is **spaces only**. YAML forbids tab characters for indentation, and every nesting level is two more spaces than its parent.

Name the file `/etc/netplan/90-lab.yaml`. The high number makes it merge last. It must be owned by root with mode `600`.

### Add the spare interface and check it merged

<!-- astrona:playground:renew -->

Use your spare interface name in place of `enp2s0`. Save this as `/etc/netplan/90-lab.yaml`:

```yaml
network:
  version: 2
  ethernets:
    enp2s0:
      dhcp4: false
      addresses:
        - 192.168.130.50/24
      nameservers:
        addresses: [192.168.130.1]
```

Set its permissions and ask Netplan for that one interface:

```sh
sudo chmod 600 /etc/netplan/90-lab.yaml
sudo netplan get ethernets.enp2s0
```

Expect just that interface's merged settings:

```text
addresses:
- 192.168.130.50/24
dhcp4: false
nameservers:
  addresses:
  - 192.168.130.1
```

`netplan get` accepted the file and now reports the spare interface next to the management one. Nothing is applied yet: this is still the desired state on paper.

## YAML indentation: spaces, never tabs

The most common Netplan error is a stray tab or a wrong indent level. YAML uses whitespace to show structure, and a tab where spaces are expected is a hard parse error.

### See the parser reject a tab

Add a line indented with a real tab character in `/etc/netplan/90-lab.yaml` (for example a tab before `dhcp4: false`), then run:

```sh
sudo netplan get
```

Expect a parse error naming the file and line:

```text
Error in network definition /etc/netplan/90-lab.yaml line 5 column 0: found character '\t' that cannot start any token
```

Netplan renders nothing while a file cannot be parsed. Replace the tab with spaces and `netplan get` works again.

> [!TIP]
> Set your editor to insert spaces when you press Tab before you touch any YAML file. It prevents this error for good.

## Rendering without applying: `netplan generate`

`netplan generate` writes the real configuration files for the backend without touching the running network. For `systemd-networkd` they go under `/run/systemd/network/`. It is how you see exactly what your YAML turns into.

### Read the file Netplan produced

Render the files, then print the one for your spare interface:

```sh
sudo netplan generate
cat /run/systemd/network/10-netplan-enp2s0.network
```

Expect a `systemd-networkd` file built from your YAML:

```text
[Match]
Name=enp2s0

[Network]
DHCP=no
Address=192.168.130.50/24
DNS=192.168.130.1
```

Your few lines of YAML became a `systemd-networkd` unit. With `renderer: NetworkManager`, the same command would write an `.nmconnection` keyfile instead: the INI-style profile file NetworkManager keeps in `/etc/NetworkManager/system-connections/`.

## Common pitfalls

> [!WARNING]
> - **Tabs or a wrong indent level.** YAML structure is whitespace. A tab is a parse error; two spaces too few or too many changes which key a setting belongs to. `netplan get` is the fast check.
> - **An address without its prefix.** `addresses: [192.168.1.10]` is invalid. It must be `192.168.1.10/24`.
> - **`gateway4:` copied from an old example.** It is deprecated. Use `routes: [{to: default, via: <ip>}]`.
> - **World-readable Netplan files.** They can hold secrets such as Wi-Fi keys, and recent Netplan warns unless they are `chmod 600`.
> - **Editing the rendered files.** Files under `/run/systemd/network/` are written again on the next `netplan generate`. Change the YAML instead.
